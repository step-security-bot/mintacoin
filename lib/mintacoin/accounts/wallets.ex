defmodule Mintacoin.Wallets do
  @moduledoc """
  This module is responsible for doing the CRUD operations for Wallets
  """
  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Repo, Wallet}

  @type id :: UUID.t()
  @type public_key :: String.t()
  @type changes :: map()
  @type wallet :: Wallet.t() | nil
  @type error :: Changeset.t()

  @spec create(changes :: changes()) :: {:ok, Wallet.t()} | {:error, error()}
  def create(changes) do
    %Wallet{}
    |> Wallet.changeset(changes)
    |> Repo.insert()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, wallet()}
  def retrieve_by_id(id), do: {:ok, Repo.get(Wallet, id)}

  @spec retrieve_by_public_key(public_key :: public_key()) :: {:ok, wallet()}
  def retrieve_by_public_key(public_key), do: {:ok, Repo.get_by(Wallet, public_key: public_key)}
end
