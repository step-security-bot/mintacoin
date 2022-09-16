defmodule Mintacoin.BlockchainTx do
  @moduledoc """
  Ecto schema for BlockchainTx
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{Account, Blockchain, Wallet}

  @type t :: %__MODULE__{
          blockchain_id: Blockchain.t(),
          wallet_id: Wallet.t(),
          successful: boolean(),
          tx_id: String.t(),
          tx_hash: String.t(),
          tx_timestamp: String.t(),
          tx_response: map()
        }

  @uuid_regex ~r/^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$/

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "blockchain_txs" do
    belongs_to(:blockchain, Blockchain, type: :binary_id)
    belongs_to(:account, Account, type: :binary_id)
    belongs_to(:wallet, Wallet, type: :binary_id)

    field(:successful, :boolean, default: false)
    field(:tx_id, :string)
    field(:tx_hash, :string)
    field(:tx_timestamp, :string)
    field(:tx_response, :map, default: %{})

    timestamps()
  end

  @spec changeset(blockchain_tx :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(blockchain_tx, changes) do
    cast(blockchain_tx, changes, [
      :successful,
      :tx_id,
      :tx_hash,
      :tx_timestamp,
      :tx_response
    ])
  end

  @spec create_changeset(blockchain_tx :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def create_changeset(blockchain_tx, changes) do
    blockchain_tx
    |> cast(changes, [
      :blockchain_id,
      :account_id,
      :wallet_id,
      :successful,
      :tx_id,
      :tx_hash,
      :tx_timestamp,
      :tx_response
    ])
    |> validate_required([:blockchain_id])
    |> validate_format(:blockchain_id, @uuid_regex, message: "blockchain_id must be a uuid")
    |> validate_format(:wallet_id, @uuid_regex, message: "wallet_id must be a uuid")
    |> validate_format(:account_id, @uuid_regex, message: "account_id must be a uuid")
    |> foreign_key_constraint(:blockchain_id)
    |> foreign_key_constraint(:wallet_id)
    |> foreign_key_constraint(:account_id)
  end
end
