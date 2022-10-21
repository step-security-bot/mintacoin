defmodule Mintacoin.Accounts.Workers.CreateTrustline do
  @moduledoc """
  Worker module to perform jobs to create an asset trustline in a blockchain and the respective balance and blockchain transaction registries
  """

  use Oban.Worker, queue: :create_trustline_queue, max_attempts: 3

  alias Ecto.{Changeset, UUID}

  alias Mintacoin.{
    Accounts.Cipher,
    AssetHolder,
    AssetHolders,
    Assets.Crypto,
    Assets.Crypto.AssetResponse,
    Balance,
    Balances,
    Blockchains,
    BlockchainTx,
    BlockchainTxs
  }

  @type asset_holder :: AssetHolder.t()
  @type balance :: Balance.t()
  @type blockchain_tx :: BlockchainTx.t() | Changeset.t() | nil
  @type id :: UUID.t()
  @type status :: :ok | :error
  @type tx_response :: {:ok, AssetResponse.t()} | {:error, map()}

  @impl true
  def perform(%Oban.Job{
        args: %{
          "asset_holder_id" => asset_holder_id,
          "encrypted_secret_key" => encrypted_secret_key,
          "asset_code" => asset_code
        }
      }) do
    {:ok, %AssetHolder{blockchain_id: blockchain_id} = asset_holder} =
      AssetHolders.retrieve_by_id(asset_holder_id)

    {:ok, %{name: blockchain_name}} = Blockchains.retrieve_by_id(blockchain_id)
    {:ok, trustor_secret_key} = Cipher.decrypt_with_system_key(encrypted_secret_key)

    [
      blockchain: blockchain_name,
      trustor_secret_key: trustor_secret_key,
      asset_code: asset_code
    ]
    |> Crypto.create_trustline()
    |> create_blockchain_tx(asset_holder)
  end

  @spec create_blockchain_tx(
          tx_response :: tx_response(),
          asset_holder :: asset_holder()
        ) :: {status(), blockchain_tx()}
  defp create_blockchain_tx({:ok, %{successful: true} = tx_response}, %{
         id: asset_holder_id,
         asset_id: asset_id,
         blockchain_id: blockchain_id,
         wallet_id: wallet_id
       }) do
    {:ok, _balance} = process_balance(asset_id, wallet_id)

    tx_response
    |> Map.take([:tx_id, :tx_hash, :tx_response, :tx_timestamp])
    |> Map.merge(%{
      blockchain_id: blockchain_id,
      asset_holder_id: asset_holder_id,
      successful: true
    })
    |> BlockchainTxs.create()
  end

  defp create_blockchain_tx(
         {:ok,
          %{tx_id: tx_id, tx_hash: tx_hash, tx_response: tx_response, tx_timestamp: tx_timestamp}},
         %{id: asset_holder_id, blockchain_id: blockchain_id}
       ) do
    {:ok, blockchain_tx} =
      BlockchainTxs.create(%{
        asset_holder_id: asset_holder_id,
        blockchain_id: blockchain_id,
        successful: false,
        tx_id: tx_id,
        tx_hash: tx_hash,
        tx_response: tx_response,
        tx_timestamp: tx_timestamp
      })

    {:error, blockchain_tx}
  end

  @spec process_balance(asset_id :: id(), wallet_id :: id()) :: {:ok, balance()}
  defp process_balance(asset_id, wallet_id) do
    case Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id) do
      {:ok, nil} -> Balances.create(%{asset_id: asset_id, wallet_id: wallet_id})
      {:ok, balance} -> {:ok, balance}
    end
  end
end
