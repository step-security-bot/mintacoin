defmodule Mintacoin.Repo.Migrations.AddAssetHolderBlockchainTxs do
  use Ecto.Migration

  def change do
    alter table(:blockchain_txs) do
      add(:asset_holder_id, references(:asset_holders, type: :uuid), null: true)
    end
  end
end
