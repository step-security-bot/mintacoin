defmodule Mintacoin.Repo.Migrations.CreateAssetHolders do
  use Ecto.Migration

  def change do
    create table(:asset_holders, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:blockchain_id, references(:blockchains, type: :uuid), null: false)
      add(:account_id, references(:accounts, type: :uuid), null: false)
      add(:wallet_id, references(:wallets, type: :uuid), null: false)
      add(:asset_id, references(:assets, type: :uuid), null: false)
      add(:is_minter, :boolean, null: false)

      timestamps()
    end

    create(unique_index(:asset_holders, [:asset_id, :wallet_id], name: :asset_wallet_index))
  end
end
