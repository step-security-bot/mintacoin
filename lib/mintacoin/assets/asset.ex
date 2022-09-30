defmodule Mintacoin.Asset do
  @moduledoc """
  Ecto schema for Asset
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{AssetHolder, BlockchainTx}

  @type code :: String.t()
  @type supply :: integer()
  @type t :: %__MODULE__{code: code(), supply: supply()}

  @code_regex ~r/^[[:alnum:]]{1,10}$/

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "assets" do
    field(:code, :string)
    field(:supply, :integer)

    has_many(:blockchain_txs, BlockchainTx)
    has_many(:asset_holders, AssetHolder)

    timestamps()
  end

  @spec changeset(asset :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(asset, changes) do
    asset
    |> cast(changes, [:supply])
    |> validate_required([:supply])
    |> validate_number(:supply, greater_than: 0)
  end

  @spec create_changeset(asset :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(asset, changes) do
    asset
    |> cast(changes, [:code, :supply])
    |> validate_required([:code, :supply])
    |> validate_format(:code, @code_regex, message: "code must be alphanumeric")
    |> validate_number(:supply, greater_than: 0)
  end
end
