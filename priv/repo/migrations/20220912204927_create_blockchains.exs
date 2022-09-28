defmodule Mintacoin.Repo.Migrations.CreateBlockchains do
  use Ecto.Migration

  def change do
    create table(:blockchains, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:network, :string, null: false)

      timestamps()
    end

    create(unique_index(:blockchains, [:name, :network]))
  end
end
