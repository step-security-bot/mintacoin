defmodule Mintacoin.Payments.Workers.CreatePayment do
  @moduledoc """
  Worker module to perform jobs to create a payment in a blockchain
  """

  use Oban.Worker, queue: :create_payment_queue, max_attempts: 3

  alias Ecto.{Changeset, UUID}

  alias Mintacoin.{
    Accounts.Cipher,
    Assets,
    Balance,
    Balances,
    BlockchainTx,
    BlockchainTxs,
    Payments,
    Payments.Crypto,
    Payments.Crypto.PaymentResponse,
    Wallet,
    Wallets
  }

  @type amount :: String.t()
  @type balance :: Balance.t()
  @type blockchain_tx :: BlockchainTx.t() | Changeset.t() | nil
  @type id :: UUID.t()
  @type status :: :ok | :error
  @type tx_response :: {:ok, PaymentResponse.t()} | {:error, map()}

  @impl true
  def perform(%Oban.Job{
        args: %{
          "source_signature" => source_signature,
          "source_wallet_id" => source_wallet_id,
          "destination_wallet_id" => destination_wallet_id,
          "blockchain_id" => blockchain_id,
          "asset_id" => asset_id,
          "amount" => amount,
          "payment_id" => payment_id
        }
      }) do
    {:ok, %{code: asset_code}} = Assets.retrieve_by_id(asset_id)

    {:ok, %Wallet{public_key: destination_public_key}} =
      Wallets.retrieve_by_id(destination_wallet_id)

    {:ok, %Wallet{encrypted_secret_key: source_encrypted_secret_key}} =
      Wallets.retrieve_by_id(source_wallet_id)

    {:ok, source_secret_key} = Cipher.decrypt(source_encrypted_secret_key, source_signature)

    [
      source_secret_key: source_secret_key,
      destination_public_key: destination_public_key,
      amount: amount,
      asset_code: asset_code
    ]
    |> Crypto.create_payment()
    |> create_blockchain_tx(
      blockchain_id,
      payment_id,
      asset_id,
      amount,
      source_wallet_id,
      destination_wallet_id
    )
  end

  @spec create_blockchain_tx(
          tx_response :: tx_response(),
          blockchain_id :: id(),
          payment_id :: id(),
          asset_id :: id(),
          amount :: amount(),
          source_wallet_id :: id(),
          destination_wallet_id :: id()
        ) :: {status(), blockchain_tx()}
  defp create_blockchain_tx(
         {:ok, %{successful: true} = tx_response},
         blockchain_id,
         payment_id,
         asset_id,
         amount,
         source_wallet_id,
         destination_wallet_id
       ) do
    Payments.update(payment_id, %{status: :completed, successful: true})

    {:ok, _balances} =
      process_payment_balance(amount, asset_id, source_wallet_id, destination_wallet_id)

    tx_response
    |> Map.take([:tx_id, :tx_hash, :tx_response, :tx_timestamp])
    |> Map.merge(%{
      blockchain_id: blockchain_id,
      payment_id: payment_id,
      successful: true
    })
    |> BlockchainTxs.create()
  end

  defp create_blockchain_tx(
         {:ok,
          %{tx_id: tx_id, tx_hash: tx_hash, tx_response: tx_response, tx_timestamp: tx_timestamp}},
         blockchain_id,
         payment_id,
         _asset_id,
         _amount,
         _source_wallet_id,
         _destination_wallet_id
       ) do
    Payments.update(payment_id, %{status: :failed, successful: false})

    {:ok, blockchain_tx} =
      BlockchainTxs.create(%{
        blockchain_id: blockchain_id,
        payment_id: payment_id,
        successful: false,
        tx_id: tx_id,
        tx_hash: tx_hash,
        tx_response: tx_response,
        tx_timestamp: tx_timestamp
      })

    {:error, blockchain_tx}
  end

  @spec process_payment_balance(
          amount :: amount(),
          asset_id :: id(),
          source_wallet_id :: id(),
          destination_wallet_id :: id()
        ) ::
          {:ok, %{destination_balance: balance(), source_balance: balance()}}
  defp process_payment_balance(
         amount,
         asset_id,
         source_wallet_id,
         destination_wallet_id
       ) do
    {:ok, %{id: source_balance_id}} =
      Balances.retrieve_by_wallet_id_and_asset_id(source_wallet_id, asset_id)

    {:ok, source_balance} = Balances.decrease_balance(source_balance_id, amount)

    {:ok, %{id: destination_balance_id}} =
      Balances.retrieve_by_wallet_id_and_asset_id(destination_wallet_id, asset_id)

    {:ok, destination_balance} = Balances.increase_balance(destination_balance_id, amount)
    {:ok, %{source_balance: source_balance, destination_balance: destination_balance}}
  end
end
