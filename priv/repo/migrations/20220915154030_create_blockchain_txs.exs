defmodule Mintacoin.Repo.Migrations.CreateBlockchainTxs do
  use Ecto.Migration

  def change do
    create table(:blockchain_txs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:blockchain_id, references(:blockchains, type: :uuid), null: false)
      add(:wallet_id, references(:wallets, type: :uuid), null: false)
      add(:successful, :boolean, null: true)
      add(:tx_id, :string, null: true)
      add(:tx_hash, :string, null: true)
      add(:tx_timestamp, :string, null: true)
      add(:tx_response, :map, null: true)

      timestamps()
    end
  end
end
