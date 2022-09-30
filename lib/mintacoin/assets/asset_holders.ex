defmodule Mintacoin.AssetHolders do
  @moduledoc """
  This module is the responsible for the CRUD operations for assets holders
  """
  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{AssetHolder, Repo}

  @type id :: UUID.t()
  @type changes :: map()
  @type error :: Changeset.t()
  @type asset_holder :: AssetHolder.t() | nil

  @spec create(changes :: changes()) :: {:ok, asset_holder()} | {:error, error()}
  def create(changes) do
    %AssetHolder{}
    |> AssetHolder.changeset(changes)
    |> Repo.insert()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, asset_holder()}
  def retrieve_by_id(id), do: {:ok, Repo.get(AssetHolder, id)}

  @spec retrieve_by_account_id_and_asset_id(account_id :: id(), asset_id :: id()) ::
          {:ok, asset_holder()}
  def retrieve_by_account_id_and_asset_id(account_id, asset_id),
    do: {:ok, Repo.get_by(AssetHolder, account_id: account_id, asset_id: asset_id)}

  @spec retrieve_by_wallet_id_and_asset_id(wallet_id :: id(), asset_id :: id()) ::
          {:ok, asset_holder()}
  def retrieve_by_wallet_id_and_asset_id(wallet_id, asset_id),
    do: {:ok, Repo.get_by(AssetHolder, wallet_id: wallet_id, asset_id: asset_id)}
end
