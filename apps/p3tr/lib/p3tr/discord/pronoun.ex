defmodule P3tr.Discord.Pronoun do
  require P3tr.Gettext
  use Discord.Commands, otp_app: :p3tr

  command "pronoun", "Pronoun management" do
    subcommand("prompt", "send Prompt")

    sub_command_group "config", "Pronoun config" do
      subcommand("default", "Load default pronouns")
      subcommand("remove-all", "Remove all pronouns")

      subcommand "add", "Add pronoun" do
        string("key", "Pronoun key", required: true)
        string("name", "Pronoun name")
        string("color", "Pronoun color")
        boolean("primary", "Primary pronoun")
      end

      subcommand "remove", "Remove pronoun" do
        role("pronoun", "Pronoun to remove", required: true)
        string("reason", "Reason for removal")
      end
    end
  end

  @default_pronouns [
    {:they, 0x9C59D1, true},
    {:she, 0xE14F4F, true},
    {:he, 0x0086FF, true},
    {:any, 0x45B31D, false},
    {:ask, 0xFCBA03, false}
  ]

  def command("pronoun", ["config" | args], interaction) do
    Nostrum.Api.create_interaction_response(
      interaction,
      interaction_response(:deferred_channel_message_with_source, flags: :ephemeral)
    )

    embeds =
      config(args, interaction)
      |> IO.inspect()

    Nostrum.Api.edit_interaction_response(
      interaction,
      interaction_response_data(embeds: embeds, content: "")
    )
  end

  defp config(["default" | _args], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    result =
      @default_pronouns
      |> Stream.map(&create_default_pronoun(guild_id, &1))
      |> Enum.into([])

    failed =
      result
      |> Enum.filter(&match?({:error, _}, &1))
      # unwrap from error tuple
      |> Enum.map(fn
        {:error, inner} -> inner
        _ -> raise "unexpected"
      end)
      |> Enum.map(&format_error/1)
      |> Enum.join("\n")

    ok =
      result
      |> Enum.filter(&match?({:ok, _}, &1))
      # unwrap from ok tuple
      |> Enum.map(fn
        {:ok, %{role_id: id, key: key}} -> "- <@&#{id}> `#{key}`"
        _ -> raise "unexpected"
      end)
      |> Enum.join("\n")

    fields =
      [{"Created", ok}, {"Failed", failed}]
      |> Enum.map(fn
        {_, ""} -> nil
        v -> v
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn {name, msg} -> %{name: name, value: msg} end)

    [
      %{
        type: :rich,
        title: "Created default pronouns",
        description: "Default pronouns loaded",
        color: 0x00FF00,
        fields: fields
      }
    ]
  end

  defp config(["add", args: args], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    key = Commands.fetch!(args, "key")
    name = Commands.get(args, "name", key)
    primary = Commands.get(args, "primary", true)

    color = 0x0000FF
    # TODO: implement
    # Commands.get(args, "color")

    color
    |> inspect()
    |> IO.warn()

    create_pronoun(guild_id, key, name, primary)
    |> case do
      {:ok, role} ->
        [
          %{
            type: :rich,
            title: "Created Role",
            description: "Role <@&#{role.role_id}> created for `#{key}`",
            color: color
          }
        ]

      {:error, {:already_exists, name}} ->
        [
          %{
            type: :rich,
            title: "Failed to create role",
            description: "Role `#{name}` already exists",
            color: 0xFF3333
          }
        ]

      {:error, :role_create_failed} ->
        [
          %{
            type: :rich,
            title: "Failed to create role",
            description: "Failed to create",
            color: 0xFF3333
          }
        ]
    end
  end

  defp config(["remove", args: args], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    role = Commands.fetch!(args, "pronoun")
    reason = Commands.get(args, "reason", "Removed by user")

    msg =
      with role when not is_nil(role) <- P3tr.Repo.Pronoun.get_role(guild_id, role),
           :ok <- P3tr.Discord.delete_role(guild_id, role.role_id, reason),
           {:ok, role} <- P3tr.Repo.Pronoun.remove_role(role) do
        msg =
          if role.name do
            "Removed role #{role.name}"
          else
            "Removed role #{role.key}"
          end

        %{type: :rich, title: "Removed role", description: msg, color: 0x00FF00}
      else
        v ->
          IO.inspect(v)

          %{
            type: :rich,
            title: "Failed to remove role",
            description: "Failed to remove role",
            color: 0xFF3333
          }
      end

    [msg]
  end

  defp config(["remove-all" | _], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    roles =
      P3tr.Repo.Pronoun.get_all(guild_id)
      |> Enum.map(& &1.role_id)
      |> IO.inspect()

    result =
      roles
      |> Enum.map(fn role ->
        {role, P3tr.Discord.delete_role(guild_id, role, "Removed by user")}
      end)
      |> Enum.map(fn
        {role, :ok} -> P3tr.Repo.Pronoun.remove_role(guild_id, role)
        {_role, {:error, error}} -> {:error, error}
      end)

    failed =
      result
      |> Enum.filter(&match?({:error, _}, &1))
      # unwrap from error tuple
      |> Enum.map(fn
        {:error, inner} -> inner
        _ -> raise "unexpected"
      end)
      |> Enum.map(&format_error/1)
      |> Enum.join("\n")

    ok =
      result
      |> Enum.filter(&match?({:ok, _}, &1))
      # unwrap from ok tuple
      |> Enum.map(fn
        {:ok, %{key: key}} -> "- `#{key}`"
        _ -> raise "unexpected"
      end)
      |> Enum.join("\n")

    fields =
      [{"Deleted", ok}, {"Failed", failed}]
      |> Enum.map(fn
        {_, ""} -> nil
        v -> v
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn {name, msg} -> %{name: name, value: msg} end)

    [
      %{
        type: :rich,
        title: "Removed all pronouns",
        color: 0x00FF00,
        fields: fields
      }
    ]
  end

  defp create_default_pronoun(guild_id, {key, color, primary}) do
    name = get_name_for_default_role(key)
    create_pronoun(guild_id, key, name, primary, color: color)
  end

  defp get_name_for_default_role(:they), do: P3tr.Gettext.dgettext("pronouns", "They/Them")
  defp get_name_for_default_role(:she), do: P3tr.Gettext.dgettext("pronoun", "She/Her")
  defp get_name_for_default_role(:he), do: P3tr.Gettext.dgettext("pronoun", "He/Him")
  defp get_name_for_default_role(:any), do: P3tr.Gettext.dgettext("pronoun", "Any Pronouns")

  defp get_name_for_default_role(:ask),
    do: P3tr.Gettext.dgettext("pronoun", "Ask for my Pronouns")

  @spec create_pronoun(Nostrum.Snowflake.t(), atom(), String.t() | nil, boolean(), keyword()) ::
          {:ok, P3tr.Repo.Pronoun.t()} | {:error, any}
  def create_pronoun(guild_id, key, name, primary, opts \\ []) when is_number(guild_id) do
    with false <- P3tr.Repo.Pronoun.exists?(guild_id, to_string(key)),
         {:ok, role} <- P3tr.Discord.create_role(__MODULE__, guild_id, name, opts),
         {:ok, role} <- P3tr.Repo.Pronoun.create_pronoun(guild_id, role, key, nil, primary) do
      {:ok, role}
    else
      true ->
        {:error, {:already_exists, key}}

      %P3tr.Repo.Pronoun{} = pronoun ->
        {:error, {:already_exists, pronoun}}

      {:error, %Ecto.Changeset{} = changeset} ->
        Nostrum.Api.delete_guild_role(guild_id, Ecto.Changeset.get_field(changeset, :role_id))
        {:error, {:invalid_changeset, changeset}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_error({:already_exists, key}), do: "- Pronoun `#{key}` already exists"
  defp format_error({:invalid_changeset, changeset}), do: "- #{inspect(changeset)}"
  defp format_error(reason), do: "- #{inspect(reason)}"
end
