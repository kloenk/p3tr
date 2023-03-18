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

  def command("pronoun", ["config" | args], interaction), do: config(args, interaction)

  defp config(["default" | _args], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    result =
      @default_pronouns
      |> Stream.map(&create_default_pronoun(guild_id, &1))
      |> Enum.into([])
      |> IO.inspect()

    IO.warn(:todo_default)
  end

  defp config(["add" , args: args ], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    key = Commands.fetch!(args, "key")
    name = Commands.get(args, "name", key)
    primary = Commands.get(args, "primary", true)
    _color = Commands.get(args, "color")
    |> inspect(
    )
    |> IO.warn()

    create_pronoun(guild_id, key, name, primary)
  end

  defp config(["remove", args: args ], %Nostrum.Struct.Interaction{guild_id: guild_id}) do
    role = Commands.fetch!(args, "pronoun")
    IO.inspect(role)
    IO.warn(:todo_remove)
  end

  def get_pronoun(guild, key) do
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

  def create_pronoun(guild_id, key, name, primary, opts \\ []) when is_number(guild_id) do
    IO.inspect(key)
    with nil <- get_pronoun(guild_id, key),
         {:ok, role} <- P3tr.Discord.create_role(__MODULE__, guild_id, name, opts),
         {:ok, role} <- P3tr.Repo.Pronoun.create_pronoun(guild_id, role.id, key, nil, primary) do
          IO.inspect(role)
          {:ok, role}
    else
      %P3tr.Repo.Pronoun{} = pronoun -> {:error, {:already_exists, pronoun}}
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        Nostrum.Api.delete_guild_role(guild_id, Ecto.Changeset.get_field(changeset, :role_id))
        {:error, {:invalid_changeset, changeset}}
      {:error, reason} -> {:error, reason}
    end
  end
end
