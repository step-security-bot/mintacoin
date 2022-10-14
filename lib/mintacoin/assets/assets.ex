defmodule Mintacoin.Assets do
  @moduledoc """
  This module is the responsible for the CRUD operations for assets and also for the aggregate operations within the assets context.
  """
  alias Ecto.{Changeset, UUID}
  alias Mintacoin.{Accounts.Cipher, Asset, AssetHolder, AssetHolders, Repo, Wallets}
  alias Mintacoin.Assets.Workers.CreateAsset, as: CreateAssetWorker

  @type id :: UUID.t()
  @type changes :: map()
  @type error :: Changeset.t()
  @type asset :: Asset.t()
  @type asset_code :: Asset.code()
  @type asset_supply :: Asset.supply()
  @type amount :: String.t()
  @type params :: map()
  @type asset_holder :: AssetHolder.t()

  @spec create(params :: params()) :: {:ok, asset()}
  def create(%{
        blockchain: %{id: blockchain_id},
        account: %{id: account_id},
        signature: signature,
        asset_code: asset_code,
        asset_supply: asset_supply
      }) do
    {:ok, %{id: wallet_id, encrypted_secret_key: encrypted_secret_key}} =
      Wallets.retrieve_by_account_id_and_blockchain_id(account_id, blockchain_id)

    {:ok, %{id: asset_id} = asset} =
      wallet_id
      |> AssetHolders.retrieve_minter_by_wallet_id_and_asset_code(asset_code)
      |> process_asset_creation(asset_code, asset_supply)

    {:ok, secret_key} = Cipher.decrypt(encrypted_secret_key, signature)
    {:ok, system_encrypted_secret_key} = Cipher.encrypt_with_system_key(secret_key)

    %{
      blockchain_id: blockchain_id,
      asset_id: asset_id,
      wallet_id: wallet_id,
      encrypted_secret_key: system_encrypted_secret_key,
      supply: asset_supply
    }
    |> CreateAssetWorker.new()
    |> Oban.insert()

    {:ok, asset}
  end

  @spec create_db_record(changes :: changes()) :: {:ok, asset()} | {:error, error()}
  def create_db_record(changes) do
    %Asset{}
    |> Asset.create_changeset(changes)
    |> Repo.insert()
  end

  @spec update(id :: id(), changes :: changes()) :: {:ok, asset()} | {:error, error()}
  def update(id, changes) do
    Asset
    |> Repo.get(id)
    |> Asset.changeset(changes)
    |> Repo.update()
  end

  @spec increase_supply(id :: id(), amount :: amount()) :: {:ok, asset()} | {:error, error()}
  def increase_supply(id, amount) do
    %Asset{supply: supply} = asset = Repo.get(Asset, id)

    new_supply =
      supply
      |> Decimal.add(amount)
      |> Decimal.to_string(:normal)

    asset
    |> Asset.changeset(%{supply: new_supply})
    |> Repo.update()
  end

  @spec retrieve_by_id(id :: id()) :: {:ok, asset() | nil}
  def retrieve_by_id(id), do: {:ok, Repo.get(Asset, id)}

  @spec process_asset_creation(
          asset_holder :: {:ok, asset_holder() | nil},
          asset_code :: asset_code(),
          asset_supply :: asset_supply()
        ) :: {:ok, asset()} | {:error, error()}
  defp process_asset_creation({:ok, %AssetHolder{asset: asset}}, _asset_code, _asset_supply),
    do: {:ok, asset}

  defp process_asset_creation({:ok, nil}, asset_code, asset_supply),
    do: create_db_record(%{code: asset_code, supply: asset_supply})
end
