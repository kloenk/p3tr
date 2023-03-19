defmodule Discord do
  alias Nostrum.Consumer

  # Macros
  defmacro __using__(opts) do
    otp = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp, __MODULE__, [])

    modules = Keyword.get(config, :modules, config[:modules])

    role_module =
      Keyword.get(opts, :role, __CALLER__.module)
      |> Macro.expand(__CALLER__)

    module_names =
      modules
      |> Enum.map(&get_module_commands/1)
      |> List.flatten()
      |> Enum.into(%{})
      |> Macro.escape()

    quote do
      @modules unquote(modules)
      @module_names unquote(module_names)

      @before_compile unquote(__MODULE__)

      unquote(role_functions(role_module, __CALLER__))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      unquote(helper_functions())
      unquote(nostrum_functions())
    end
  end

  # Helpers to access internal state
  defp helper_functions do
    quote do
      def modules do
        @modules
      end

      def module_names do
        @module_names
      end

      def command_module(name) do
        Map.get(@module_names, name)
      end
    end
  end

  defp role_function(nil, _caller), do: nil
  defp role_functions(false, _caller), do: nil

  defp role_functions(module, caller) do
    IO.inspect(module)
    IO.inspect(caller.module)

    if module == caller.module do
      quote do
        @behaviour Discord.Role
        unquote(Discord.Role.role_helpers(module))
      end
    else
      quote do
        unquote(Discord.Role.role_helpers(module))
      end
    end
  end

  # Nostrum wrappers
  defp nostrum_functions do
    quote do
      use Nostrum.Consumer
      def start_link, do: Consumer.start_link(__MODULE__)

      @impl Nostrum.Consumer
      def handle_event(
            {:INTERACTION_CREATE,
             %Nostrum.Struct.Interaction{
               data: %Nostrum.Struct.ApplicationCommandInteractionData{name: command}
             } = interaction, _ws_state}
          ) do
        module = command_module(command)

        args = unquote(__MODULE__).get_command_list(interaction.data)

        apply(module, :command, [command, args, interaction])
      end

      @impl Nostrum.Consumer
      def handle_event(_event), do: :noop
    end
  end

  defp get_module_commands(module) do
    module.global_commands()
    |> Enum.map(&Map.get(&1, :name))
    |> Enum.map(&{&1, module})
  end

  @doc false
  def get_command_list(%Nostrum.Struct.ApplicationCommandInteractionData{options: [options]}) do
    options
    |> get_command_list()
  end

  def get_command_list(%Nostrum.Struct.ApplicationCommandInteractionDataOption{
        name: name,
        options: [option],
        value: nil
      }) do
    [name | get_command_list(option)]
    # |> List.flatten()
  end

  def get_command_list(%Nostrum.Struct.ApplicationCommandInteractionDataOption{
        name: name,
        value: nil,
        options: options
      }) do
    [name, format_command_args(options)]
  end

  def get_command_list(%Nostrum.Struct.ApplicationCommandInteractionDataOption{} = options) do
    [format_command_args(options)]
  end

  def get_command_list(options) when is_list(options) do
    [format_command_args(options)]
  end

  defp format_command_args(
         %Nostrum.Struct.ApplicationCommandInteractionDataOption{
           name: name
         } = opt
       ) do
    {:args, %{name => opt}}
  end

  defp format_command_args(args) when is_list(args) do
    args =
      args
      |> Enum.map(fn %Nostrum.Struct.ApplicationCommandInteractionDataOption{name: name} = opt ->
        {name, opt}
      end)
      |> Enum.into(%{})

    {:args, args}
  end

  # Nostrum helpers
  def register_global_commands(module) when is_atom(module) do
    module.global_commands()
    |> Enum.map(&register_command/1)
  end

  def register_command(command) do
    Nostrum.Api.create_global_application_command(command)
  end
end
