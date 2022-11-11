defmodule Mintacoin.Payments.Workers.CreatePaymentsTest do
  @moduledoc """
  This module is used to test the worker to create an payments in a blockchain
  """
  use Mintacoin.DataCase, async: false
  use Oban.Testing, repo: Mintacoin.Repo

  import Mintacoin.Factory, only: [insert: 1, insert: 2]

  alias Ecto.Adapters.SQL.Sandbox

  alias Mintacoin.{
    Accounts,
    Accounts.Cipher,
    Assets,
    Balance,
    Balances,
    BlockchainTx,
    Payments.StellarMock
  }

  alias Mintacoin.Payments.Workers.CreatePayment, as: CreatePaymentWorker

  setup do
    :ok = Sandbox.checkout(Mintacoin.Repo)

    payment = insert(:payment)

    %{
      payment: payment,
      balance_amount: "1000.0",
      valid_payment_amount: 2,
      invalid_payment_amount: 1_000_000
    }
  end

  describe "with successful transaction" do
    setup [
      :successful_transaction,
      :create_users_wallets,
      :create_asset_in_network,
      :create_asset_trustor
    ]

    test "with valid params", %{
      source_signature: secret_key,
      source_wallet: %{id: source_wallet_id},
      destination_wallet: %{id: destination_wallet_id},
      blockchain: %{id: blockchain_id},
      new_asset: %{id: asset_id},
      payment: %{id: payment_id},
      valid_payment_amount: valid_payment_amount
    } do
      {:ok,
       %BlockchainTx{
         payment_id: ^payment_id,
         blockchain_id: ^blockchain_id,
         successful: true
       }} =
        perform_job(CreatePaymentWorker, %{
          source_signature: secret_key,
          source_wallet_id: source_wallet_id,
          destination_wallet_id: destination_wallet_id,
          blockchain_id: blockchain_id,
          asset_id: asset_id,
          amount: valid_payment_amount,
          payment_id: payment_id
        })

      {:ok, %Balance{balance: "2.0", wallet_id: ^destination_wallet_id, asset_id: ^asset_id}} =
        Balances.retrieve_by_wallet_id_and_asset_id(destination_wallet_id, asset_id)
    end
  end

  describe "with unsuccessful transaction" do
    setup [
      :successful_transaction,
      :create_users_wallets,
      :create_asset_in_network,
      :create_asset_trustor,
      :unsuccessful_transaction
    ]

    test "with valid params", %{
      source_signature: secret_key,
      source_wallet: %{id: source_wallet_id},
      destination_wallet: %{id: destination_wallet_id},
      blockchain: %{id: blockchain_id},
      new_asset: %{id: asset_id},
      payment: %{id: payment_id},
      valid_payment_amount: valid_payment_amount
    } do
      {:error,
       %BlockchainTx{
         payment_id: ^payment_id,
         blockchain_id: ^blockchain_id,
         successful: false
       }} =
        perform_job(CreatePaymentWorker, %{
          source_signature: secret_key,
          source_wallet_id: source_wallet_id,
          destination_wallet_id: destination_wallet_id,
          blockchain_id: blockchain_id,
          asset_id: asset_id,
          amount: valid_payment_amount,
          payment_id: payment_id
        })

      {:ok, %Balance{balance: "0.0", wallet_id: ^destination_wallet_id, asset_id: ^asset_id}} =
        Balances.retrieve_by_wallet_id_and_asset_id(destination_wallet_id, asset_id)
    end
  end

  defp create_users_wallets(_context) do
    blockchain = insert(:blockchain, %{name: "stellar"})

    secret_key = "SBJCNL6H5WFDK2CUAWU2IAWGWQLGER77URPYXUJ5B4N4GY2HNEBL5JJG"

    %{
      account: source_account,
      wallet: source_wallet,
      signature: source_signature
    } = create_user_wallet(secret_key, blockchain)

    %{
      account: destination_account,
      wallet: destination_wallet,
      signature: destination_signature
    } = create_user_wallet(secret_key, blockchain)

    %{
      blockchain: blockchain,
      source_account: source_account,
      destination_account: destination_account,
      secret_key: secret_key,
      source_wallet: source_wallet,
      source_signature: source_signature,
      destination_wallet: destination_wallet,
      destination_signature: destination_signature
    }
  end

  defp create_user_wallet(secret_key, blockchain) do
    %{signature: signature} = account = insert(:account)

    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    wallet =
      insert(:wallet, %{
        account: account,
        blockchain: blockchain,
        encrypted_secret_key: encrypted_secret_key
      })

    %{
      account: account,
      wallet: wallet,
      signature: signature
    }
  end

  defp create_asset_in_network(%{
         blockchain: blockchain,
         source_wallet: source_wallet,
         source_signature: source_signature
       }) do
    {:ok, asset} =
      Assets.create(%{
        wallet: source_wallet,
        signature: source_signature,
        asset_code: "MTK",
        asset_supply: "100"
      })

    insert(:asset_holder, %{
      # wallet: source_wallet,
      asset: asset,
      blockchain: blockchain,
      is_minter: false
    })

    %{new_asset: asset}
  end

  defp create_asset_trustor(%{
         new_asset: asset,
         destination_wallet: destination_wallet,
         destination_signature: destination_signature
       }) do
    {:ok, new_asset_holder} =
      Accounts.create_trustline(%{
        asset: asset,
        trustor_wallet: destination_wallet,
        signature: destination_signature
      })

    %{new_asset_holder: new_asset_holder}
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
