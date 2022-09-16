defmodule Mintacoin.BlockchainTxs do
  @moduledoc """
  This module is the responsible for the CRUD operations for blockchains transactions and also for the aggregate operations within the blockchain context.
  """
  import Ecto.Query

  alias Ecto.{Changeset, Query.CastError, UUID}
  alias Mintacoin.{BlockchainTx, Repo, Wallet}

  @type id :: UUID.t()
  @type wallet_id :: Wallet.t()
  @type tx_id :: String.t()
  @type changes :: map()
  @type parameter :: keyword()
  @type error :: Changeset.t() | :invalid_params | :not_found

  @spec create(changes :: changes()) :: {:ok, BlockchainTx.t()} | {:error, error()}
  def create(%{} = changes) do
    %BlockchainTx{}
    |> BlockchainTx.create_changeset(changes)
    |> Repo.insert()
  end

  def create(_changes), do: {:error, :invalid_params}

  @spec update(id :: id(), changes :: changes()) :: {:ok, BlockchainTx.t()} | {:error, error()}
  def update(id, %{} = changes) when is_binary(id) do
    BlockchainTx
    |> Repo.get(id)
    |> BlockchainTx.changeset(changes)
    |> Repo.update()
  rescue
    FunctionClauseError -> {:error, :not_found}
  end

  def update(_id, _changes), do: {:error, :invalid_params}

  @spec retrieve_by_id(id :: id()) :: {:ok, BlockchainTx.t() | nil} | {:error, error()}
  def retrieve_by_id(id) when is_binary(id) do
    {:ok, Repo.get(BlockchainTx, id)}
  rescue
    CastError -> {:ok, nil}
  end

  def retrieve_by_id(_id), do: {:error, :invalid_params}

  @spec retrieve_by_tx_id(tx_id :: tx_id()) :: {:ok, BlockchainTx.t() | nil} | {:error, error()}
  def retrieve_by_tx_id(tx_id) when is_binary(tx_id),
    do: {:ok, Repo.get_by(BlockchainTx, tx_id: tx_id)}

  def retrieve_by_tx_id(_tx_id), do: {:error, :invalid_params}

  @spec retrieve_by_wallet_id(wallet_id :: wallet_id()) ::
          {:ok, list(BlockchainTx.t())} | {:error, error()}
  def retrieve_by_wallet_id(wallet_id) when is_binary(wallet_id) do
    query = from(btx in BlockchainTx, where: btx.wallet_id == ^wallet_id)

    {:ok, Repo.all(query)}
  rescue
    _error -> {:ok, []}
  end

  def retrieve_by_wallet_id(_wallet_id), do: {:error, :invalid_params}
end
