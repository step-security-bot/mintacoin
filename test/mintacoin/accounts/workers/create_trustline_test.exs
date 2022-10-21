defmodule Mintacoin.Accounts.Workers.CreateTrustlineTest do
  @moduledoc """
  This module is used to test worker to create trustline in the blockchains
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox

  alias Mintacoin.{
    Accounts,
    Accounts.Cipher,
    Assets,
    Assets.StellarMock,
    Balance,
    Balances,
    BlockchainTx
  }

  alias Mintacoin.Accounts.Workers.CreateTrustline, as: CreateTrustlineWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    blockchain = insert(:blockchain, %{name: "stellar"})

    %{
      blockchain: blockchain,
      new_code: "ART",
      new_supply: "440.20",
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "with successful transaction" do
    setup [
      :successful_transaction,
      :create_asset,
      :create_trustor
    ]

    test "with valid params", %{
      blockchain: %{id: blockchain_id},
      trustor_asset_holder: %{id: asset_holder_id},
      trustor_encrypted_secret_key: encrypted_secret_key,
      trustor_wallet: %{id: wallet_id},
      asset: %{id: asset_id, code: code}
    } do
      {:ok,
       %BlockchainTx{
         asset_holder_id: ^asset_holder_id,
         blockchain_id: ^blockchain_id,
         successful: true
       }} =
        perform_job(CreateTrustlineWorker, %{
          blockchain_id: blockchain_id,
          asset_holder_id: asset_holder_id,
          encrypted_secret_key: encrypted_secret_key,
          asset_code: code
        })

      {:ok, %Balance{balance: "0.0", wallet_id: ^wallet_id, asset_id: ^asset_id}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end

    test "when the user create the same trustline", %{
      blockchain: %{id: blockchain_id},
      trustor_second_asset_holder: %{id: asset_holder_id},
      trustor_encrypted_secret_key: encrypted_secret_key,
      trustor_wallet: %{id: wallet_id},
      second_asset: %{id: asset_id, code: code}
    } do
      {:ok,
       %BlockchainTx{
         asset_holder_id: ^asset_holder_id,
         blockchain_id: ^blockchain_id,
         successful: true
       }} =
        perform_job(CreateTrustlineWorker, %{
          blockchain_id: blockchain_id,
          asset_holder_id: asset_holder_id,
          encrypted_secret_key: encrypted_secret_key,
          asset_code: code
        })

      {:ok, %Balance{balance: "0.0", wallet_id: ^wallet_id, asset_id: ^asset_id}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end
  end

  describe "with unsuccessful transaction" do
    setup [
      :successful_transaction,
      :create_asset,
      :create_trustor,
      :unsuccessful_transaction
    ]

    test "with valid params", %{
      blockchain: %{id: blockchain_id},
      trustor_asset_holder: %{id: asset_holder_id},
      trustor_encrypted_secret_key: encrypted_secret_key,
      trustor_wallet: %{id: wallet_id},
      asset: %{id: asset_id, code: code}
    } do
      {:error,
       %BlockchainTx{
         asset_holder_id: ^asset_holder_id,
         blockchain_id: ^blockchain_id,
         successful: false
       }} =
        perform_job(CreateTrustlineWorker, %{
          asset_holder_id: asset_holder_id,
          encrypted_secret_key: encrypted_secret_key,
          asset_code: code
        })

      {:ok, nil} = Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end
  end

  defp create_asset(%{blockchain: blockchain, new_code: new_code, new_supply: new_supply}) do
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
        asset_code: "MTK",
        asset_supply: "400"
      })

    {:ok, second_asset} =
      Assets.create(%{
        wallet: wallet,
        signature: signature,
        asset_code: new_code,
        asset_supply: new_supply
      })

    %{
      asset: asset,
      second_asset: second_asset,
      minter_wallet: wallet
    }
  end

  defp create_trustor(%{
         blockchain: blockchain,
         asset: asset,
         second_asset: second_asset
       }) do
    %{signature: signature} = account = insert(:account)

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)
    {:ok, system_encrypted_secret_key} = Cipher.encrypt_with_system_key(secret_key)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    asset_holder =
      insert(:asset_holder, %{
        wallet: wallet,
        asset: asset,
        blockchain: blockchain,
        is_minter: false
      })

    {:ok, second_asset_holder} =
      Accounts.create_trustline(%{
        asset: second_asset,
        trustor_wallet: wallet,
        signature: signature
      })

    %{
      trustor_asset_holder: asset_holder,
      trustor_second_asset_holder: second_asset_holder,
      trustor_wallet: wallet,
      trustor_encrypted_secret_key: system_encrypted_secret_key
    }
  end

  defp successful_transaction(_context) do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)
    Application.put_env(:stellar_mock, :tx_status, true)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
      Application.delete_env(:stellar_mock, :tx_status)
    end)
  end

  defp unsuccessful_transaction(_context) do
    Application.put_env(:mintacoin, :crypto_impl, StellarMock)
    Application.put_env(:stellar_mock, :tx_status, false)

    on_exit(fn ->
      Application.delete_env(:mintacoin, :crypto_impl)
      Application.delete_env(:stellar_mock, :tx_status)
    end)
  end
end
