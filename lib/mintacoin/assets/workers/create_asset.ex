defmodule Mintacoin.Assets.Workers.CreateAsset do
  @moduledoc """
  Worker module to perform jobs to create an asset in a blockchain and the respective asset_holder, balance and blockchain transaction registries
  """

  use Oban.Worker, queue: :create_asset_queue, max_attempts: 3

  alias Ecto.{Changeset, UUID}

  alias Mintacoin.{
    Accounts.Cipher,
    Asset,
    AssetHolder,
    AssetHolders,
    Assets,
    Assets.Crypto,
    Assets.Crypto.AssetResponse,
    Balances,
    Blockchains,
    BlockchainTx,
    BlockchainTxs,
    Wallets
  }

  @type asset :: Asset.t()
  @type asset_holder :: AssetHolder.t()
  @type blockchain_tx :: BlockchainTx.t() | Changeset.t() | nil
  @type id :: UUID.t()
  @type status :: :ok | :error
  @type supply :: String.t()
  @type tx_response :: {:ok, AssetResponse.t()} | {:error, map()}

  @impl true
  def perform(%Oban.Job{
        args: %{
          "blockchain_id" => blockchain_id,
          "asset_id" => asset_id,
          "wallet_id" => wallet_id,
          "encrypted_secret_key" => encrypted_secret_key,
          "supply" => supply
        }
      }) do
    {:ok, %{code: asset_code} = asset} = Assets.retrieve_by_id(asset_id)
    {:ok, %{name: blockchain_name}} = Blockchains.retrieve_by_id(blockchain_id)
    {:ok, distributor_secret_key} = Cipher.decrypt_with_system_key(encrypted_secret_key)
    float_supply = supply |> Decimal.new() |> Decimal.to_float()

    [
      blockchain: blockchain_name,
      distributor_secret_key: distributor_secret_key,
      asset_code: asset_code,
      asset_supply: float_supply
    ]
    |> Crypto.create_asset()
    |> create_blockchain_tx(asset, supply, wallet_id)
  end

  @spec create_blockchain_tx(
          tx_response :: tx_response(),
          asset :: asset(),
          supply :: supply(),
          wallet_id :: id()
        ) :: {status(), blockchain_tx()}
  defp create_blockchain_tx(
         {:ok, %{successful: true} = tx_response},
         %{id: asset_id, code: code},
         supply,
         wallet_id
       ) do
    {:ok, asset_holder} =
      AssetHolders.retrieve_minter_by_wallet_id_and_asset_code(wallet_id, code)

    {:ok, %{blockchain_id: blockchain_id}} =
      process_transaction(asset_holder, supply, asset_id, wallet_id)

    tx_response
    |> Map.take([:tx_id, :tx_hash, :tx_response, :tx_timestamp])
    |> Map.merge(%{
      blockchain_id: blockchain_id,
      asset_id: asset_id,
      successful: true
    })
    |> BlockchainTxs.create()
  end

  defp create_blockchain_tx(
         {:ok,
          %{tx_id: tx_id, tx_hash: tx_hash, tx_response: tx_response, tx_timestamp: tx_timestamp}},
         %{id: asset_id},
         _supply,
         wallet_id
       ) do
    {:ok, %{blockchain_id: blockchain_id}} = Wallets.retrieve_by_id(wallet_id)

    {:ok, blockchain_tx} =
      BlockchainTxs.create(%{
        asset_id: asset_id,
        blockchain_id: blockchain_id,
        successful: false,
        tx_id: tx_id,
        tx_hash: tx_hash,
        tx_response: tx_response,
        tx_timestamp: tx_timestamp
      })

    {:error, blockchain_tx}
  end

  @spec process_transaction(
          asset_holder :: asset_holder() | nil,
          supply :: supply(),
          asset_id :: id(),
          wallet_id :: id()
        ) :: {:ok, asset_holder()}
  defp process_transaction(
         %AssetHolder{} = asset_holder,
         supply,
         asset_id,
         wallet_id
       ) do
    {:ok, _asset} = Assets.increase_supply(asset_id, supply)

    {:ok, %{id: balance_id}} = Balances.retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id)
    {:ok, _balance} = Balances.increase_balance(balance_id, supply)

    {:ok, asset_holder}
  end

  defp process_transaction(
         nil,
         supply,
         asset_id,
         wallet_id
       ) do
    {:ok, %{account_id: account_id, blockchain_id: blockchain_id}} =
      Wallets.retrieve_by_id(wallet_id)

    {:ok, _balance} =
      Balances.create(%{asset_id: asset_id, balance: supply, wallet_id: wallet_id})

    {:ok, asset_holder} =
      AssetHolders.create(%{
        blockchain_id: blockchain_id,
        account_id: account_id,
        asset_id: asset_id,
        wallet_id: wallet_id,
        is_minter: true
      })

    {:ok, asset_holder}
  end
end
