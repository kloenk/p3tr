defmodule P3tr.Repo.Role do
  use TypedEctoSchema
  import Ecto.Changeset
  import P3tr.Repo, only: [validate_snowflake: 2]
  import Ecto.Query

  @behaviour Discord.Role

  @primary_key {:role_id, :integer, []}

  schema "roles" do
    field :guild_id, :integer
    # field :role_id, :integer, primary_key: true
    field :module, Ecto.Enum,
      values: [
        {P3tr.Discord.Pronoun, "P3tr.Discord.Pronoun"},
        {P3tr.Discord.Topic, "P3tr.Discord.Topic"}
      ]
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
  def store_role(module, guild, role) when is_integer(guild) and is_integer(role) do
    create_changeset(%__MODULE__{}, %{guild_id: guild, role_id: role, module: module})
    |> P3tr.Repo.insert()
    |> case do
      {:ok, _} -> :ok
      v -> v
    end
  end

  @impl Discord.Role
  def delete_role(guild, role) do
    from(m in __MODULE__, where: m.guild_id == ^guild and m.role_id == ^role)
    |> P3tr.Repo.one()
    |> P3tr.Repo.delete()
    |> case do
      {:ok, _} -> :ok
      v -> v
    end
  end
end
