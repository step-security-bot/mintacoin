defmodule Mintacoin.Customer do
  @moduledoc """
  Ecto schema for customers
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.{Changeset, UUID}
  alias Mintacoin.Account

  @type id :: UUID.t()
  @type name :: String.t()
  @type email :: String.t()
  @type encrypted_api_key :: String.t()
  @type api_key :: String.t()

  @type t :: %__MODULE__{
          name: name(),
          email: email(),
          encrypted_api_key: encrypted_api_key(),
          api_key: api_key()
        }

  @code_regex ~r/^[A-Za-z0-9\._%+.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "customers" do
    field(:email, :string)
    field(:name, :string)
    field(:encrypted_api_key, :string)
    field(:api_key, :string, virtual: true)

    has_many(:account, Account)

    timestamps()
  end

  @spec changeset(customer :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(customer, changes) do
    cast(customer, changes, [:encrypted_api_key, :name])
  end

  @spec create_changeset(customer :: %__MODULE__{}, attrs :: map()) :: Changeset.t()
  def create_changeset(customer, attrs) do
    customer
    |> cast(attrs, [:api_key, :email, :encrypted_api_key, :name])
    |> validate_required([:api_key, :email, :encrypted_api_key, :name])
    |> validate_format(:email, @code_regex)
    |> unique_constraint(:email)
  end
end
