defmodule Discord.Commands.Register do
  @moduledoc false
  use Bitwise, only_operators: true

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, __MODULE__)

    gettext = Keyword.get(opts, :gettext, config[:gettext])
    allowed_langs = Keyword.get(opts, :allowed_langs, config[:allowed_langs])

    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__), only: [command: 3, localization_dict: 1]

      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      @localization_gettext unquote(gettext)
      @localization_langs unquote(allowed_langs)
      @__attr_storage__ []

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl Discord.Commands
      def global_commands do
        @commands
      end
    end
  end

  defmacro command(name, description, opts) do
    quote do
      @commands unquote(__MODULE__).create_command(
                  unquote(name),
                  unquote(description),
                  unquote(opts)
                )
    end
  end

  defmacro create_command(name, description, opts \\ []) do
    create_command_int(name, description, opts)
  end

  defp create_command_int(name, description, opts \\ []) do
    extra =
      Keyword.get(opts, :extra, %{})
      |> Macro.escape()

    type =
      Keyword.get(opts, :type, :chat_input)
      |> command_input_type()

    options =
      if type == 1 do
        # Keyword.get(opts, :options, [])
        do_command_block(name, opts[:do])
      else
        nil
      end

    default_member_permissions =
      Keyword.get(opts, :member_permission)
      |> default_member_permission_conv()

    dm_permission = Keyword.get(opts, :dm_permission)

    quote do
      Map.merge(unquote(extra), %{
        type: unquote(type),
        name: unquote(name),
        name_localizations: localization_dict(unquote(name)),
        description: unquote(description),
        description_localizations: localization_dict(unquote(description)),
        options: unquote(options),
        default_member_permissions: unquote(default_member_permissions),
        dm_permission: unquote(dm_permission)
      })
    end
  end

  defp do_command_block(_name, nil), do: nil

  defp do_command_block(name, block) do
    attr_name =
      "__command_block_#{name}__"
      |> String.to_atom()

    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, unquote(attr_name), accumulate: true)

      try do
        unquote(put_attribute(attr_name))
        unquote(block)

        Module.get_attribute(__MODULE__, unquote(attr_name), [])
        |> Enum.sort_by(&Map.get(&1, :required, false), :desc)
      after
        unquote(pop_attribute())
        Module.delete_attribute(__MODULE__, unquote(attr_name))
      end
    end
  end

  defmacro create_option(name, description, opts \\ []) do
    extra =
      Keyword.get(opts, :extra, %{})
      |> Macro.escape()

    required = Keyword.get(opts, :required, nil)

    type =
      Keyword.get(opts, :type)
      |> command_option_type()

    choices = Keyword.get(opts, :choices)
    options = Keyword.get(opts, :do)
    options = do_command_block(name, options)

    channel_types =
      Keyword.get(opts, :channel_types)
      |> command_channel_types()

    min_value = Keyword.get(opts, :min_value)
    max_value = Keyword.get(opts, :max_value)
    min_length = Keyword.get(opts, :min_length)
    max_length = Keyword.get(opts, :max_length)
    autocomplete = Keyword.get(opts, :autocomplete)

    quote do
      Map.merge(unquote(extra), %{
        type: unquote(type),
        name: unquote(name),
        name_localizations: localization_dict(unquote(name)),
        description: unquote(description),
        description_localizations: localization_dict(unquote(description)),
        required: unquote(required),
        choices: unquote(choices),
        options: unquote(options),
        channel_types: unquote(channel_types),
        min_value: unquote(min_value),
        max_value: unquote(max_value),
        min_length: unquote(min_length),
        max_length: unquote(max_length),
        autocomplete: unquote(autocomplete)
      })
    end
  end

  defmacro option(name, description, opts \\ []) do
    quote do
      attribute = unquote(get_attribute())

      Module.put_attribute(
        __MODULE__,
        attribute,
        create_option(unquote(name), unquote(description), unquote(opts))
      )
    end
  end

  defmacro subcommand(name, description, opts \\ []) do
    opts = Keyword.put(opts, :type, :sub_command)

    quote do
      option(unquote(name), unquote(description), unquote(opts))
    end
  end

  defmacro sub_command_group(name, description, opts \\ []) do
    opts = Keyword.put(opts, :type, :sub_command_group)

    quote do
      option(unquote(name), unquote(description), unquote(opts))
    end
  end

  defmacro string(name, description, opts \\ []) do
    opts = Keyword.put(opts, :type, :string)

    quote do
      option(unquote(name), unquote(description), unquote(opts))
    end
  end

  defmacro role(name, description, opts \\ []) do
    opts = Keyword.put(opts, :type, :role)

    quote do
      option(unquote(name), unquote(description), unquote(opts))
    end
  end

  defmacro localization_dict(key) do
    # langs = Application.fetch_env!(:fleet_bot, FleetBot.Discord)[:discord_allowed_langs]

    quote do
      Gettext.known_locales(@localization_gettext)
      |> Stream.filter(fn lang ->
        Enum.member?(@localization_langs, lang)
      end)
      |> Stream.map(fn lang ->
        Gettext.with_locale(lang, fn ->
          {lang, @localization_gettext.dgettext("discord_commands", unquote(key))}
        end)
      end)
      |> Enum.into(%{})
    end
  end

  ### Private macro helpers
  defp put_attribute(attr) do
    attr = Macro.expand_once(attr, __ENV__)

    quote do
      attrs = [unquote(attr)] ++ Module.get_attribute(__MODULE__, :__attr_storage__, [])
      Module.put_attribute(__MODULE__, :__attr_storage__, attrs)
    end
  end

  defp pop_attribute() do
    quote do
      case Module.get_attribute(__MODULE__, :__attr_storage__, []) do
        [] ->
          nil

        [head | tail] ->
          Module.put_attribute(__MODULE__, :__attr_storage__, tail)
          head
      end
    end
  end

  defp get_attribute() do
    quote do
      Module.get_attribute(__MODULE__, :__attr_storage__, [])
      |> hd
    end
  end

  defp command_input_type(:chat_input), do: 1
  defp command_input_type(:user), do: 2
  defp command_input_type(:message), do: 3
  defp command_input_type(v) when is_integer(v), do: v

  defp default_member_permission_conv(v) when is_binary(v) or is_nil(v), do: v
  defp default_member_permission_conv(v) when is_integer(v), do: Integer.to_string(v)
  defp default_member_permission_conv(:view_channel), do: 1 <<< 10
  defp default_member_permission_conv(:send_message), do: 1 <<< 11

  defp command_option_type(:sub_command), do: 1
  defp command_option_type(:sub_command_group), do: 2
  defp command_option_type(:string), do: 3
  defp command_option_type(:integer), do: 4
  defp command_option_type(:boolean), do: 5
  defp command_option_type(:user), do: 6
  defp command_option_type(:channel), do: 7
  defp command_option_type(:role), do: 8
  defp command_option_type(:mentionable), do: 9
  defp command_option_type(:number), do: 10
  defp command_option_type(:attachment), do: 11
  defp command_option_type(v) when is_number(v), do: v

  defp command_channel_types(nil), do: nil
  defp command_channel_types(v) when is_atom(v) or is_number(v), do: [command_channel_type(v)]

  defp command_channel_types(v) when is_list(v),
    do: Enum.map(v, fn v -> command_channel_type(v) end) |> Enum.into([])

  defp command_channel_type(:guild_text), do: 0
  defp command_channel_type(:dm), do: 1
  defp command_channel_type(:guild_voice), do: 2
  defp command_channel_type(:group_dm), do: 3
  defp command_channel_type(:guild_category), do: 4
  defp command_channel_type(:guild_announcement), do: 5
  defp command_channel_type(:announcement_thread), do: 10
  defp command_channel_type(:public_thread), do: 11
  defp command_channel_type(:private_thread), do: 12
  defp command_channel_type(:guild_stage_voice), do: 13
  defp command_channel_type(:guild_directory), do: 14
  defp command_channel_type(:guild_forum), do: 15
  defp command_channel_type(v) when is_number(v), do: v
  # TODO: import all from https://discord.com/developers/docs/topics/permissions and allow arrays
end
