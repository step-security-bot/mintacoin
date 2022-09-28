defmodule Mintacoin.Repo.Migrations.AddAssetToBlockchainTx do
  use Ecto.Migration

  def change do
    alter table(:blockchain_txs) do
      add(:asset_id, references(:assets, type: :uuid), null: true)
    end
  end
end
