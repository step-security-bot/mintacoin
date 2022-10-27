defmodule Mintacoin.AssetHolder do
  @moduledoc """
  Ecto schema for AssetHolder
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{Account, Asset, Blockchain, BlockchainTx, Wallet}

  @type t :: %__MODULE__{
          is_minter: boolean(),
          blockchain: Blockchain.t(),
          account: Account.t(),
          asset: Asset.t(),
          wallet: Wallet.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "asset_holders" do
    belongs_to(:blockchain, Blockchain, type: :binary_id)
    belongs_to(:account, Account, type: :binary_id)
    belongs_to(:asset, Asset, type: :binary_id)
    belongs_to(:wallet, Wallet, type: :binary_id)

    has_many(:blockchain_txs, BlockchainTx)

    field(:is_minter, :boolean, default: false)

    timestamps()
  end

  @spec changeset(asset_holder :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(asset_holder, changes) do
    asset_holder
    |> cast(changes, [
      :blockchain_id,
      :account_id,
      :asset_id,
      :wallet_id,
      :is_minter
    ])
    |> validate_required([
      :blockchain_id,
      :account_id,
      :asset_id,
      :wallet_id,
      :is_minter
    ])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:blockchain_id)
    |> foreign_key_constraint(:wallet_id)
    |> unique_constraint([:asset_id, :wallet_id], name: :asset_wallet_index)
  end
end
