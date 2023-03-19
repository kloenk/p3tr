defmodule P3tr.Repo.Migrations.Topic do
  use Ecto.Migration

  def change do
    create table(:topics, primary_key: false) do
      add :role_id, :bigint, null: false, primary_key: true
      add :guild_id, :bigint, null: false
      add :key, :string, size: 40, null: false
      add :name, :string, size: 40
      add :description, :string, size: 250
    end

    create index(:topics, [:guild_id], comment: "Topic Guild index")
    create unique_index(:topics, [:guild_id, :key], comment: "Topic Guild Key index")
  end
end
