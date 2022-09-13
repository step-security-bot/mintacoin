defmodule Mintacoin.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:address, :string, unique: true, null: false)
      add(:encrypted_signature, :string, null: false)

      timestamps()
    end

    create unique_index(:accounts, [:encrypted_signature])
    create unique_index(:accounts, [:address])
  end
end
