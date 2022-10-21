defmodule Mintacoin.Accounts.AccountsTest do
  @moduledoc """
    This module is used to group common tests for Accounts functions
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox

  alias Mintacoin.{
    Account,
    Accounts,
    Accounts.Cipher,
    AssetHolder,
    Assets,
    BlockchainTx,
    BlockchainTxs
  }

  alias Mintacoin.Accounts.StellarMock, as: AccountsStellarMock
  alias Mintacoin.Assets.StellarMock, as: AssetsStellarMock

  alias Mintacoin.Accounts.Workers.CreateAccount, as: CreateAccountWorker
  alias Mintacoin.Accounts.Workers.CreateTrustline, as: CreateTrustlineWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    Application.put_env(:mintacoin, :crypto_impl, AccountsStellarMock)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
    end)

    %{
      invalid_address: "INVALID_ADDRESS",
      not_found_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  test "create_db_record/1" do
    {:ok, %Account{}} = Accounts.create_db_record()
  end

  describe "retrieve_by_id/1" do
    test "with valid id" do
      %Account{id: id} = insert(:account)
      {:ok, %Account{id: ^id}} = Accounts.retrieve_by_id(id)
    end

    test "with non existing id", %{not_found_uuid: not_found_uuid} do
      {:ok, nil} = Accounts.retrieve_by_id(not_found_uuid)
    end
  end

  describe "retrieve_by_address/1" do
    test "with valid address" do
      %Account{address: address} = insert(:account)
      {:ok, %Account{address: ^address}} = Accounts.retrieve_by_address(address)
    end

    test "with non existing address", %{invalid_address: invalid_address} do
      {:ok, nil} = Accounts.retrieve_by_address(invalid_address)
    end
  end

  describe "recover_signature/2" do
    test "should return signature" do
      %Account{address: address, seed_words: seed_words, signature: signature} = insert(:account)

      {:ok, ^signature} = Accounts.recover_signature(address, seed_words)
    end

    test "with invalid seed words" do
      %Account{address: address} = insert(:account)

      {:error, :invalid_seed_words} =
        Accounts.recover_signature(
          address,
          "these are twelve really bad seed words for the account retrieve by"
        )
    end
  end

  describe "create/1" do
    setup do
      blockchain = insert(:blockchain, %{name: "stellar"})

      %{blockchain: blockchain}
    end

    test "enqueuing create account job", %{blockchain: blockchain} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, %Account{}} = Accounts.create(blockchain)

        assert_enqueued(
          worker: CreateAccountWorker,
          queue: :create_account_queue
        )
      end)
    end

    test "with valid params", %{blockchain: %{id: blockchain_id} = blockchain} do
      {:ok, %Account{id: account_id}} = Accounts.create(blockchain)

      {:ok, [blockchain_tx | _tail]} = BlockchainTxs.retrieve_by_account_id(account_id)

      %BlockchainTx{blockchain_id: ^blockchain_id, account_id: ^account_id} = blockchain_tx
    end
  end

  describe "create_trustline/1" do
    setup [:successful_transaction, :create_asset, :create_trustor, :create_trustline]

    test "enqueuing create trustline job", %{
      asset: %{id: asset_id} = asset,
      blockchain: %{id: blockchain_id},
      trustor_wallet: trustor_wallet,
      trustor_signature: trustor_signature
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok,
         %AssetHolder{
           asset_id: ^asset_id,
           blockchain_id: ^blockchain_id,
           is_minter: false
         }} =
          Accounts.create_trustline(%{
            asset: asset,
            trustor_wallet: trustor_wallet,
            signature: trustor_signature
          })

        assert_enqueued(
          worker: CreateTrustlineWorker,
          queue: :create_trustline_queue
        )
      end)
    end

    test "with valid params", %{
      asset: %{id: asset_id} = asset,
      blockchain: %{id: blockchain_id},
      trustor_wallet: trustor_wallet,
      trustor_signature: trustor_signature
    } do
      {:ok,
       %AssetHolder{
         asset_id: ^asset_id,
         blockchain_id: ^blockchain_id,
         is_minter: false
       }} =
        Accounts.create_trustline(%{
          asset: asset,
          trustor_wallet: trustor_wallet,
          signature: trustor_signature
        })
    end

    test "when the user create the same trustline", %{
      new_asset: %{id: asset_id} = new_asset,
      new_asset_holder: %{id: asset_holder_id},
      blockchain: %{id: blockchain_id},
      trustor_wallet: trustor_wallet,
      trustor_signature: trustor_signature
    } do
      {:ok,
       %AssetHolder{
         id: ^asset_holder_id,
         asset_id: ^asset_id,
         blockchain_id: ^blockchain_id,
         is_minter: false
       }} =
        Accounts.create_trustline(%{
          asset: new_asset,
          trustor_wallet: trustor_wallet,
          signature: trustor_signature
        })
    end

    test "when signature is invalid", %{
      asset: asset,
      trustor_wallet: trustor_wallet
    } do
      {:error, :decoding_error} =
        Accounts.create_trustline(%{
          asset: asset,
          trustor_wallet: trustor_wallet,
          signature: "OR4N6LBCSWMBNPJEW6KBZ62LQNKW4H7WPE5MNIOIX732LQXBU6A"
        })
    end
  end

  defp create_asset(_context) do
    asset_code = "MTK"
    supply = "55.65"

    new_code = "TTY"
    new_supply = "43"

    blockchain = insert(:blockchain, %{name: "stellar"})
    %{signature: signature} = account = insert(:account)

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    {:ok, asset} =
      Assets.create(%{
        wallet: wallet,
        signature: signature,
        asset_code: asset_code,
        asset_supply: supply
      })

    {:ok, new_asset} =
      Assets.create(%{
        wallet: wallet,
        signature: signature,
        asset_code: new_code,
        asset_supply: new_supply
      })

    %{
      asset: asset,
      new_asset: new_asset,
      code: asset_code,
      new_code: new_code,
      supply: supply,
      new_supply: new_supply,
      minter_account: account,
      minter_wallet: wallet,
      blockchain: blockchain
    }
  end

  defp create_trustor(%{blockchain: blockchain}) do
    %{signature: signature} = account = insert(:account)

    secret_key = "SDCRAVD2NLVJSLMUU2EZRMT57JUNQG7NAG3FOUVRPBPT6DCGHTQW7I3W"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    %{
      trustor_account: account,
      trustor_wallet: wallet,
      trustor_signature: signature
    }
  end

  defp create_trustline(%{
         trustor_wallet: trustor_wallet,
         trustor_signature: trustor_signature,
         new_asset: new_asset
       }) do
    {:ok, asset_holder} =
      Accounts.create_trustline(%{
        asset: new_asset,
        trustor_wallet: trustor_wallet,
        signature: trustor_signature
      })

    %{new_asset_holder: asset_holder}
  end

  defp successful_transaction(_context) do
    Application.put_env(:mintacoin, :crypto_impl, AssetsStellarMock)
    Application.put_env(:stellar_mock, :tx_status, true)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
      Application.delete_env(:stellar_mock, :tx_status)
    end)
  end
end
