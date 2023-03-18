defmodule P3tr.Repo.Migrations.Pronouns do
  use Ecto.Migration

  def change do
    create table(:pronouns, primary_key: false) do
      add :role_id, :bigint, null: false, primary_key: true
      add :guild_id, :bigint, null: false
      add :key, :string, size: 40, null: false
      add :name, :string, size: 40


      add :primary, :boolean, default: true
    end

    create index(:pronouns, [:guild_id], comment: "Pronoun Guild index")
    create unique_index(:pronouns, [:guild_id, :key], comment: "Pronoung Guild Key index")
  end
end
