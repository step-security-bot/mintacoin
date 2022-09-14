defmodule Mintacoin.Blockchain do
  @moduledoc """
  Ecto schema for Blockchain
  """

  use Ecto.Schema

  import Ecto.Changeset
  import EctoEnum

  alias Ecto.Changeset

  @type name :: Name
  @type network :: Network
  @type t :: %__MODULE__{name: name(), network: network()}

  defenum(Name, :name, [
    :stellar
  ])

  defenum(Network, :network, [
    :mainnet,
    :testnet
  ])

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "blockchains" do
    field(:name, Name)
    field(:network, Network)

    timestamps()
  end

  @spec changeset(blockchain :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(blockchain, changes) do
    blockchain
    |> cast(changes, [:name, :network])
    |> validate_required([:name, :network])
    |> unique_constraint([:name, :network])
  end
end
