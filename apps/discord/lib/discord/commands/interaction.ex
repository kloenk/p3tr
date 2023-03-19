defmodule Discord.Commands.Interaction do
  @moduledoc false
  alias Hex.API.Key

  # Macors
  defmacro __using__(_opts) do
    quote do
      require unquote(__MODULE__)

      import unquote(__MODULE__),
        only: [
          interaction_response: 1,
          interaction_response: 2,
          interaction_response_data: 0,
          interaction_response_data: 1,
          button: 1,
          button: 2
        ]
    end
  end

  defmacro interaction_response(
             type,
             data \\ []
           ) do
    type = interaction_response_type(type)

    quote do
      %{
        type: unquote(type),
        data: interaction_response_data(unquote(data))
        # unquote(data)
      }
    end
  end

  defmacro interaction_response_data(opts \\ []) do
    tts = Keyword.get(opts, :tts)

    content =
      Keyword.get(opts, :content)
      |> case do
        v when is_binary(v) ->
          quote do
            # TODO: localization
            # FleetBot.Gettext.dgettext("discord_commands", unquote(v), unquote(opts))
            unquote(v)
          end

        nil ->
          nil
      end

    embeds = Keyword.get(opts, :embeds)
    allowed_mentions = Keyword.get(opts, :allowed_mentions)

    flags =
      Keyword.get(opts, :flags)
      |> interaction_response_data_flags()

    components = Keyword.get(opts, :components)
    attachements = Keyword.get(opts, :attachements)

    quote do
      %{
        tts: unquote(tts),
        content: unquote(content),
        embeds: unquote(embeds),
        allowed_mentions: unquote(allowed_mentions),
        flags: unquote(flags),
        components: unquote(components),
        attachements: unquote(attachements)
      }
    end
  end

  defmacro button(style, opts \\ []) do
    type = component_type(:button)
    style = style

    quote do
      %Nostrum.Struct.Component{
        type: unquote(type),
        style: unquote(__MODULE__).button_style(unquote(style)),
        label: unquote(opts[:label]),
        emoji: unquote(opts[:emoji]),
        custom_id: unquote(opts[:custom_id]),
        url: unquote(opts[:url]),
        disabled: unquote(opts[:disabled])
      }
    end
  end

  ## Macro helpers
  import Bitwise

  def interaction_response_type(:pong), do: 1
  def interaction_response_type(:channel_message_with_source), do: 4
  def interaction_response_type(:deferred_channel_message_with_source), do: 5
  def interaction_response_type(:deferred_update_channel), do: 6
  def interaction_response_type(:update_message), do: 7
  def interaction_response_type(:application_command_autocomplete_result), do: 8
  def interaction_response_type(:modal), do: 9
  def interaction_response_type(v) when is_number(v), do: v

  def interaction_response_data_flags(flags) when is_list(flags) do
    flags
    |> Enum.map(&interaction_response_data_flags/1)
    |> Enum.reduce(0, fn flag, acc ->
      flag ||| acc
    end)
  end

  def interaction_response_data_flags(:suppress_embeds), do: 1 <<< 3
  def interaction_response_data_flags(:ephemeral), do: 1 <<< 6
  def interaction_response_data_flags(v) when is_number(v), do: v
  def interaction_response_data_flags(nil), do: nil

  def component_type(:action_row), do: 1
  def component_type(:button), do: 2
  def component_type(:string_select), do: 3
  def component_type(:text_input), do: 4
  def component_type(:user_select), do: 5
  def component_type(:role), do: 6
  def component_type(:mentionable_select), do: 7
  def component_type(:channel_select), do: 8
  def component_type(v) when is_number(v), do: v

  def button_style(:primary), do: 1
  def button_style(:secondary), do: 2
  def button_style(:success), do: 3
  def button_style(:danger), do: 4
  def button_style(:link), do: 5
  def button_style(v) when is_number(v), do: v
end
