defmodule Mintacoin.Balance do
  @moduledoc """
  Ecto schema for Balance
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{Asset, Wallet}

  @type balance :: String.t()
  @type t :: %__MODULE__{
          asset: Asset.t(),
          balance: balance(),
          wallet: Wallet.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "balances" do
    field(:balance, :string, default: "0.0")

    belongs_to(:asset, Asset, type: :binary_id)
    belongs_to(:wallet, Wallet, type: :binary_id)

    timestamps()
  end

  @spec create_changeset(balance :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(balance, changes) do
    balance
    |> cast(changes, [:balance, :asset_id, :wallet_id])
    |> validate_required([:balance, :asset_id, :wallet_id])
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:wallet_id)
    |> unique_constraint([:asset_id, :wallet_id], name: :asset_wallet__balance_index)
  end

  @spec changeset(balance :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(balance, changes) do
    balance
    |> cast(changes, [:balance])
    |> validate_required([:balance])
  end
end
