defmodule P3tr.Repo.Pronoun do
  use TypedEctoSchema
  import Ecto.Changeset
  import P3tr.Repo, only: [validate_snowflake: 2]

  @primary_key {:role_id, :integer, []}

  typed_schema "pronouns" do
    #field :role_id, :integer, primary_key: true
    field :guild_id, :integer
    field :key, :string
    field :name, :string
    field :primary, :boolean, default: true
  end

  def create_pronoun(guild, role, key, name, primary) when is_atom(key) and is_integer(role), do: create_pronoun(guild, role, to_string(key), name, primary)
  def create_pronoun(guild, role, key, name, primary) when is_binary(key) and is_integer(role) do
    create_changeset(%{
      guild_id: guild,
      role_id: role,
      key: key,
      name: name,
      primary: primary
    })
    |> P3tr.Repo.insert()
  end

  def create_changeset(pronoun \\ %__MODULE__{}, attrs) do
    pronoun
    |> cast(attrs, [:guild_id, :role_id, :key, :name, :primary])
    |> validate_snowflake(:guild_id)
    |> validate_snowflake(:role_id)
    |> validate_key()
    |> validate_name()
    |> unique_constraint([:role_id], name: :pronouns_pkey)
  end

  defp validate_key(changeset) do
    changeset
    |> validate_required(:key)
    |> validate_length(:key, max: 40)
    |> unique_constraint([:guild_id, :key])
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, max: 40)
  end
end
