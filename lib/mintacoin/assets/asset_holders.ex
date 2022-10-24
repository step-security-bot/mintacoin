defmodule Mintacoin.AssetHolders do
  @moduledoc """
  This module is the responsible for the CRUD operations for assets holders
  """
  import Ecto.Query

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Asset, AssetHolder, Repo, Wallets}

  @type id :: UUID.t()
  @type changes :: map()
  @type error :: Changeset.t()
  @type asset_holder :: AssetHolder.t() | nil
  @type asset_code :: String.t()

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

  @spec retrieve_minter_by_wallet_id_and_asset_code(wallet_id :: id(), asset_code :: asset_code()) ::
          {:ok, asset_holder()}
  def retrieve_minter_by_wallet_id_and_asset_code(wallet_id, asset_code) do
    {:ok, %{account_id: account_id}} = Wallets.retrieve_by_id(wallet_id)

    query =
      from(ah in AssetHolder,
        join: as in Asset,
        on: as.id == ah.asset_id,
        where:
          ah.account_id == ^account_id and ah.wallet_id == ^wallet_id and as.code == ^asset_code and
            ah.is_minter == true,
        preload: [asset: as]
      )

    {:ok, Repo.one(query)}
  end

  @spec retrieve_minter_by_asset_id(asset_id :: id()) :: {:ok, asset_holder()}
  def retrieve_minter_by_asset_id(asset_id) do
    asset_holder =
      AssetHolder
      |> Repo.get_by(asset_id: asset_id, is_minter: true)
      |> Repo.preload(:account)

    {:ok, asset_holder}
  end
end
