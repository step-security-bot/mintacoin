defmodule Mintacoin.Assets.Workers.CreateAssetTest do
  @moduledoc """
  This module is used to test the worker to create an asset in a blockchain
  """

  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox

  alias Mintacoin.{
    Accounts.Cipher,
    AssetHolder,
    AssetHolders,
    Assets,
    Assets.StellarMock,
    Balance,
    Balances,
    BlockchainTx
  }

  alias Mintacoin.Assets.Workers.CreateAsset, as: CreateAssetWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    asset = insert(:asset)

    %{
      asset: asset,
      new_code: "ART",
      new_supply: "440.20"
    }
  end

  describe "with successful transaction" do
    setup [:successful_transaction, :create_user_wallet, :create_asset_in_network]

    test "with valid params", %{
      asset: %{id: asset_id, supply: supply},
      blockchain: %{id: blockchain_id},
      wallet: %{id: wallet_id},
      system_encrypted_secret_key: system_encrypted_secret_key
    } do
      {:ok, %BlockchainTx{blockchain_id: ^blockchain_id, asset_id: ^asset_id, successful: true}} =
        perform_job(CreateAssetWorker, %{
          blockchain_id: blockchain_id,
          asset_id: asset_id,
          wallet_id: wallet_id,
          encrypted_secret_key: system_encrypted_secret_key,
          supply: supply
        })

      {:ok, %AssetHolder{is_minter: true}} =
        AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

      {:ok, %Balance{balance: ^supply}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end

    test "when the user create the same asset", %{
      new_asset: %{id: asset_id, supply: supply},
      blockchain: %{id: blockchain_id},
      system_encrypted_secret_key: system_encrypted_secret_key,
      wallet: %{id: wallet_id},
      new_supply: new_supply
    } do
      {:ok, %BlockchainTx{blockchain_id: ^blockchain_id, asset_id: ^asset_id, successful: true}} =
        perform_job(CreateAssetWorker, %{
          blockchain_id: blockchain_id,
          asset_id: asset_id,
          wallet_id: wallet_id,
          encrypted_secret_key: system_encrypted_secret_key,
          supply: new_supply
        })

      end_supply = add(supply, new_supply)

      {:ok, %{supply: ^end_supply}} = Assets.retrieve_by_id(asset_id)

      {:ok, %AssetHolder{is_minter: true}} =
        AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

      {:ok, %Balance{balance: ^end_supply}} =
        Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end
  end

  describe "with unsuccessful transaction" do
    setup [:unsuccessful_transaction, :create_user_wallet]

    test "with valid params", %{
      asset: %{id: asset_id, supply: supply},
      blockchain: %{id: blockchain_id},
      wallet: %{id: wallet_id},
      system_encrypted_secret_key: system_encrypted_secret_key
    } do
      {:error,
       %BlockchainTx{blockchain_id: ^blockchain_id, asset_id: ^asset_id, successful: false}} =
        perform_job(CreateAssetWorker, %{
          blockchain_id: blockchain_id,
          asset_id: asset_id,
          wallet_id: wallet_id,
          encrypted_secret_key: system_encrypted_secret_key,
          supply: supply
        })

      {:ok, nil} = AssetHolders.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)

      {:ok, nil} = Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    end
  end

  defp create_user_wallet(_context) do
    blockchain = insert(:blockchain, %{name: "stellar"})
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

    %{
      blockchain: blockchain,
      account: account,
      wallet: wallet,
      signature: signature,
      system_encrypted_secret_key: system_encrypted_secret_key
    }
  end

  defp create_asset_in_network(%{
         wallet: wallet,
         signature: signature
       }) do
    {:ok, asset} =
      Assets.create(%{
        wallet: wallet,
        signature: signature,
        asset_code: "MTK",
        asset_supply: "123.675675"
      })

    %{new_asset: asset}
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
