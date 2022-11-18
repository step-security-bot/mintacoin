defmodule Mintacoin.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:email, :string, null: false)
      add(:name, :string, null: false)
      add(:encrypted_api_key, :string, null: false)

      timestamps()
    end

    create unique_index(:customers, [:email])
  end
end
