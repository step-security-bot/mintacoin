defmodule Mintacoin.Wallet do
  @moduledoc """
  Ecto schema for Wallet
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset
  alias Mintacoin.{Account, AssetHolder, Balance, Blockchain, BlockchainTx}

  @type t :: %__MODULE__{
          public_key: String.t(),
          encrypted_secret_key: String.t(),
          account: Account.t(),
          blockchain: Blockchain.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "wallets" do
    field(:public_key, :string)
    field(:encrypted_secret_key, :string)
    field(:secret_key, :string, virtual: true)

    belongs_to(:account, Account, type: :binary_id)
    belongs_to(:blockchain, Blockchain, type: :binary_id)

    has_many(:blockchain_txs, BlockchainTx)
    has_many(:asset_holders, AssetHolder)
    has_many(:balances, Balance)

    timestamps()
  end

  @spec changeset(wallet :: %__MODULE__{}, changes :: map()) :: Changeset.t()
  def changeset(wallet, changeset) do
    wallet
    |> cast(changeset, [
      :public_key,
      :encrypted_secret_key,
      :secret_key,
      :account_id,
      :blockchain_id
    ])
    |> validate_required([
      :public_key,
      :encrypted_secret_key,
      :secret_key,
      :account_id,
      :blockchain_id
    ])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:blockchain_id)
    |> unique_constraint(:public_key)
    |> unique_constraint([:account_id, :blockchain_id], name: :account_blockchain_index)
  end
end
