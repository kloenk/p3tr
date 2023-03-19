defmodule P3tr.Repo.Topic do
  use TypedEctoSchema
  import Ecto.Changeset
  import P3tr.Repo, only: [validate_snowflake: 2]
  import Ecto.Query

  @primary_key {:role_id, :integer, []}

  typed_schema "topics" do
    # field :role_id, :integer, primary_key: true
    field :guild_id, :integer
    field :key, :string
    field :name, :string
    field :description, :string
  end

  def exists?(guild, key) do
    P3tr.Repo.exists?(from p in __MODULE__, where: p.guild_id == ^guild and p.key == ^key)
  end

  def get(guild, id) when is_integer(guild) and is_integer(id) do
    P3tr.Repo.get_by(__MODULE__, guild_id: guild, role_id: id)
  end

  def get(guild, id) when is_integer(guild) and is_binary(id) do
    P3tr.Repo.get_by(__MODULE__, guild_id: guild, key: id)
  end

  def get_all(guild) do
    P3tr.Repo.all(from p in __MODULE__, where: p.guild_id == ^guild)
  end

  def remove(guild, id) do
    get(guild, id)
    |> remove
  end

  def remove(topic) do
    P3tr.Repo.delete(topic)
  end

  def create(guild, role, key, name, description) when is_binary(key) do
    create_changeset(%{
      guild_id: guild,
      role_id: role,
      key: key,
      name: name,
      description: description
    })
    |> P3tr.Repo.insert()
  end

  def create_changeset(topic \\ %__MODULE__{}, attrs) do
    topic
    |> cast(attrs, [:guild_id, :role_id, :key, :name, :description])
    |> validate_snowflake(:guild_id)
    |> validate_snowflake(:role_id)
    |> validate_key
    |> unique_constraint([:role_id], name: :topics_pkey)
  end

  defp validate_key(changeset) do
    changeset
    |> validate_required(:key)
    |> validate_length(:key, max: 40)
    |> unique_constraint([:guild_id, :key])
  end
end
