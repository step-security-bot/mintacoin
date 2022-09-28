defmodule Mintacoin.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table(:wallets, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:public_key, :string, null: false)
      add(:encrypted_secret_key, :string, null: false)

      add(:account_id, references(:accounts, type: :uuid), null: false)
      add(:blockchain_id, references(:blockchains, type: :uuid), null: false)

      timestamps()
    end

    create(unique_index(:wallets, :public_key))
    create(unique_index(:wallets, [:account_id, :blockchain_id], name: :account_blockchain_index))
  end
end
