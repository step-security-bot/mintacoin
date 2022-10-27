defmodule Mintacoin.Repo.Migrations.UpdateAssetTable do
  use Ecto.Migration

  def change do
    alter table("assets") do
      modify(:supply, :string, null: false)
    end
  end
end
