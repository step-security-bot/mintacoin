defmodule Mintacoin.Assets.AssetsTest do
  @moduledoc """
  This module is used to group common tests for Assets functions
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.{Adapters.SQL.Sandbox, Changeset}

  alias Mintacoin.{
    Accounts.Cipher,
    Asset,
    AssetHolder,
    AssetHolders,
    Assets,
    Assets.StellarMock,
    Balance,
    Balances,
    BlockchainTx,
    BlockchainTxs
  }

  alias Mintacoin.Assets.Workers.CreateAsset, as: CreateAssetWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    asset = insert(:asset)

    %{
      asset: asset,
      code: "MTK",
      supply: "1000",
      new_code: "ART",
      new_supply: "440.20",
      not_existing_uuid: "d9cb83d6-05f5-4557-b5d0-9e1728c42091"
    }
  end

  describe "create_db_record/1" do
    test "with valid params", %{code: code, supply: supply} do
      {:ok, %Asset{code: ^code, supply: ^supply}} =
        Assets.create_db_record(%{code: code, supply: supply})
    end

    test "with invalid code", %{supply: supply} do
      {:error,
       %Changeset{
         errors: [
           {:code, {"code must be alphanumeric", _detail}}
           | _tail
         ]
       }} = Assets.create_db_record(%{code: "M&L", supply: supply})
    end

    test "with invalid supply", %{code: code} do
      {:error,
       %Changeset{
         errors: [
           {:supply, {"is invalid", _detail}}
           | _tail
         ]
       }} = Assets.create_db_record(%{code: code, supply: -1})
    end

    test "when missing params" do
      {:error,
       %Changeset{
         errors: [
           code: {"can't be blank", _},
           supply: {"can't be blank", _}
         ]
       }} = Assets.create_db_record(%{})
    end
  end

  describe "update/2" do
    test "with valid supply", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id, supply: "100"}} = Assets.update(id, %{supply: "100"})
    end
  end

  describe "increase_supply/2" do
    test "with valid amount", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id, supply: "1100"}} = Assets.increase_supply(id, "100")
    end
  end

  describe "retrieve_by_id/1" do
    test "when id exist", %{asset: %{id: id}} do
      {:ok, %Asset{id: ^id}} = Assets.retrieve_by_id(id)
    end

    test "when id doesn't exist", %{not_existing_uuid: not_existing_uuid} do
      {:ok, nil} = Assets.retrieve_by_id(not_existing_uuid)
    end
  end

  describe "create/1 with successful transaction" do
    setup [:successful_transaction, :create_user_wallet, :create_asset_in_network]

    test "enqueuing create asset job", %{
      blockchain: blockchain,
      account: account,
      signature: signature,
      new_code: code,
      new_supply: supply
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, %Asset{}} =
          Assets.create(%{
            blockchain: blockchain,
            account: account,
            signature: signature,
            asset_code: code,
            asset_supply: supply
          })

        assert_enqueued(
          worker: CreateAssetWorker,
          queue: :create_asset_queue
        )
      end)
    end

    test "when is a new asset for the user", %{
      blockchain: %{id: blockchain_id} = blockchain,
      account: account,
      wallet: %{id: wallet_id},
      signature: signature,
      new_code: asset_code,
      new_supply: asset_supply
    } do
      {:ok, %Asset{id: asset_id, supply: ^asset_supply}} =
        Assets.create(%{
          blockchain: blockchain,
          account: account,
          signature: signature,
          asset_code: asset_code,
          asset_supply: asset_supply
        })

      {:ok,
       [
         %BlockchainTx{blockchain_id: ^blockchain_id, asset_id: ^asset_id, successful: true}
         | _tail
       ]} = BlockchainTxs.retrieve_by_asset_id(asset_id)

      {:ok, %AssetHolder{is_minter: true}} =
        AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

      {:ok, %Balance{balance: ^asset_supply}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end

    test "when the user create the same asset", %{
      asset: %{id: asset_id},
      blockchain: %{id: blockchain_id} = blockchain,
      account: account,
      wallet: %{id: wallet_id},
      signature: signature,
      code: asset_code,
      supply: asset_supply,
      new_supply: new_supply
    } do
      {:ok, %Asset{id: ^asset_id}} =
        Assets.create(%{
          blockchain: blockchain,
          account: account,
          signature: signature,
          asset_code: asset_code,
          asset_supply: new_supply
        })

      end_supply = add(asset_supply, new_supply)

      {:ok, %{supply: ^end_supply}} = Assets.retrieve_by_id(asset_id)

      {:ok,
       [
         %BlockchainTx{blockchain_id: ^blockchain_id, asset_id: ^asset_id, successful: true}
         | _tail
       ]} = BlockchainTxs.retrieve_by_asset_id(asset_id)

      {:ok, %Balance{balance: ^end_supply}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end
  end

  describe "create/1 with unsuccessful transaction" do
    setup [:unsuccessful_transaction, :create_user_wallet]

    test "when is a new asset for the user", %{
      blockchain: %{id: blockchain_id} = blockchain,
      account: account,
      wallet: %{id: wallet_id},
      signature: signature,
      new_code: asset_code,
      new_supply: asset_supply
    } do
      {:ok, %Asset{id: asset_id, supply: ^asset_supply}} =
        Assets.create(%{
          blockchain: blockchain,
          account: account,
          signature: signature,
          asset_code: asset_code,
          asset_supply: asset_supply
        })

      {:ok,
       [
         %BlockchainTx{blockchain_id: ^blockchain_id, asset_id: ^asset_id, successful: false}
         | _tail
       ]} = BlockchainTxs.retrieve_by_asset_id(asset_id)

      {:ok, nil} = AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

      {:ok, nil} = Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end
  end

  defp create_user_wallet(_context) do
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

    %{
      blockchain: blockchain,
      account: account,
      wallet: wallet,
      signature: signature
    }
  end

  defp create_asset_in_network(%{
         blockchain: blockchain,
         account: account,
         signature: signature,
         code: code,
         supply: supply
       }) do
    {:ok, asset} =
      Assets.create(%{
        blockchain: blockchain,
        account: account,
        signature: signature,
        asset_code: code,
        asset_supply: supply
      })

    %{asset: asset}
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

  # adds and returns a string
  defp add(a, b) do
    a
    |> Decimal.add(b)
    |> Decimal.to_string(:normal)
  end
end
