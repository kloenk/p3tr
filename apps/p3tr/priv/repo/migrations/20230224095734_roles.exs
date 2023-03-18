defmodule P3tr.Repo.Migrations.Roles do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :role_id, :bigint, null: false, primary_key: true
      add :guild_id, :bigint, null: false
      add :module, :string
    end

    create index(:roles, [:guild_id])
    create unique_index(:roles, [:guild_id, :role_id])
  end
end
