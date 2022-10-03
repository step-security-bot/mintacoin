defmodule Mintacoin.Repo.Migrations.CreateBalances do
  use Ecto.Migration

  def change do
    create table(:balances, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:asset_id, references(:assets, type: :uuid), null: false)
      add(:wallet_id, references(:wallets, type: :uuid), null: false)
      add(:balance, :string, null: false)

      timestamps()
    end

    create(unique_index(:balances, [:asset_id, :wallet_id], name: :asset_wallet__balance_index))
  end
end
