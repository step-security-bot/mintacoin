defmodule Mintacoin.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:code, :string, null: false)
      add(:supply, :integer, null: false)

      timestamps()
    end
  end
end
