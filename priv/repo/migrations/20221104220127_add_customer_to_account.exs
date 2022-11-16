defmodule Mintacoin.Repo.Migrations.AddCustomerToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:customer_id, references(:customers, type: :uuid), null: true)
    end
  end
end
