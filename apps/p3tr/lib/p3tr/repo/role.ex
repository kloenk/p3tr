defmodule P3tr.Repo.Role do
  use TypedEctoSchema
  import Ecto.Changeset
  import P3tr.Repo, only: [validate_snowflake: 2]

  @behaviour Discord.Role

  @primary_key {:role_id, :integer, []}

  schema "roles" do
    field :guild_id, :integer
    #field :role_id, :integer, primary_key: true
    field :module, Ecto.Enum, values: [{P3tr.Discord.Pronoun, "P3tr.Discord.Pronoun"}]
  end

  def create_changeset(role \\ %__MODULE__{}, attrs) do
    role
    |> cast(attrs, [:guild_id, :role_id, :module])
    |> validate_snowflake(:guild_id)
    |> validate_snowflake(:role_id)
    |> validate_required([:guild_id, :role_id, :module])
  end

  # Discord.Role
  @impl Discord.Role
  def store_role(module, guild, role) do
    create_changeset(%__MODULE__{}, %{guild_id: guild, role_id: role, module: module})
    |> P3tr.Repo.insert()
    :ok
  end
end
