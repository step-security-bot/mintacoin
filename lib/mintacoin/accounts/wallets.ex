defmodule Mintacoin.Wallets do
  @moduledoc """
  This module is responsible for doing the CRUD operations for Wallets
  """
  alias Ecto.{Changeset, Query.CastError, UUID}
  alias Mintacoin.{Repo, Wallet}

  @type id :: UUID.t()
  @type public_key :: String.t()
  @type changes :: map()
  @type error :: Changeset.t() | :invalid_params
  @type parameter :: keyword()

  @spec create(changes :: changes()) :: {:ok, Wallet.t()} | {:error, error()}
  def create(%{} = changes) do
    %Wallet{}
    |> Wallet.changeset(changes)
    |> Repo.insert()
  end

  def create(_changes), do: {:error, :invalid_params}

  @spec retrieve_by_id(id :: id()) :: {:ok, Wallet.t() | nil} | {:error, error()}
  def retrieve_by_id(id) when is_binary(id) do
    {:ok, Repo.get_by(Wallet, id: id)}
  rescue
    CastError -> {:ok, nil}
  end

  def retrieve_by_id(_id), do: {:error, :invalid_params}

  @spec retrieve_by_public_key(public_key :: public_key()) ::
          {:ok, Wallet.t() | nil} | {:error, error()}
  def retrieve_by_public_key(public_key) when is_binary(public_key),
    do: {:ok, Repo.get_by(Wallet, public_key: public_key)}

  def retrieve_by_public_key(_public_key), do: {:error, :invalid_params}
end
