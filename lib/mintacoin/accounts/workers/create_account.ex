defmodule Mintacoin.Accounts.Workers.CreateAccount do
  @moduledoc """
  Worker module to perform jobs to create an account in a blockchain and the respective wallet and blockchain transaction registries
  """

  use Oban.Worker, queue: :create_account_queue, max_attempts: 3

  alias Ecto.{Changeset, UUID}

  alias Mintacoin.{
    Accounts.Cipher,
    Accounts.Crypto,
    Accounts.Crypto.AccountResponse,
    Blockchains,
    BlockchainTx,
    BlockchainTxs,
    Wallet,
    Wallets
  }

  @type status :: :ok | :error
  @type id :: UUID.t()
  @type tx_response :: AccountResponse.t()
  @type signature :: String.t()
  @type blockchainTx :: BlockchainTx.t() | Changeset.t()
  @type wallet :: Wallet.t() | Changeset.t()
  @type error :: {:error, any()}

  @impl true
  def perform(%Oban.Job{
        args: %{
          "account_id" => account_id,
          "blockchain_id" => blockchain_id,
          "encrypted_signature" => encrypted_signature
        }
      }) do
    {:ok, %{name: blockchain_name}} = Blockchains.retrieve_by_id(blockchain_id)
    {:ok, signature} = Cipher.decrypt_with_system_key(encrypted_signature)

    [blockchain: blockchain_name]
    |> Crypto.create_account()
    |> create_blockchain_tx(account_id, blockchain_id, signature)
  end

  @spec create_blockchain_tx(
          {:ok, tx_response()} | error(),
          account_id :: id(),
          blockchain_id :: id(),
          signature :: signature()
        ) :: {status(), blockchainTx()}
  defp create_blockchain_tx(
         {:ok, %{successful: true} = tx_response},
         account_id,
         blockchain_id,
         signature
       ) do
    {:ok, %{id: wallet_id}} = create_wallet(tx_response, account_id, blockchain_id, signature)

    tx_response
    |> Map.take([:tx_id, :tx_hash, :tx_response, :tx_timestamp])
    |> Map.merge(%{
      wallet_id: wallet_id,
      account_id: account_id,
      blockchain_id: blockchain_id,
      successful: true
    })
    |> BlockchainTxs.create()
  end

  defp create_blockchain_tx(
         {:ok,
          %{tx_id: tx_id, tx_hash: tx_hash, tx_response: tx_response, tx_timestamp: tx_timestamp}},
         account_id,
         blockchain_id,
         _signature
       ) do
    {:ok, blockchain_tx} =
      BlockchainTxs.create(%{
        account_id: account_id,
        blockchain_id: blockchain_id,
        successful: false,
        tx_id: tx_id,
        tx_hash: tx_hash,
        tx_response: tx_response,
        tx_timestamp: tx_timestamp
      })

    {:error, blockchain_tx}
  end

  @spec create_wallet(
          tx_response :: tx_response(),
          account_id :: id(),
          blockchain_id :: id(),
          signature :: signature()
        ) :: {status(), wallet()}
  defp create_wallet(
         %{
           public_key: public_key,
           secret_key: secret_key
         },
         account_id,
         blockchain_id,
         signature
       ) do
    {:ok, encrypted_secret_key} = Cipher.encrypt(secret_key, signature)

    Wallets.create(%{
      public_key: public_key,
      secret_key: secret_key,
      encrypted_secret_key: encrypted_secret_key,
      account_id: account_id,
      blockchain_id: blockchain_id
    })
  end
end
