defmodule Discord.Commands do
  @doc """
  Execute a command
  """
  @callback command(String.t(), %Nostrum.Struct.Interaction{}) :: :ok | {:error, term()}

  @doc false
  @callback global_commands() :: [Nostrum.Struct.ApplicationCommand.application_command_map()]

  # Macros
  defmacro __using__(opts) do
    quote do
      @behaviour unquote(__MODULE__)
      use Discord.Commands.Register, unquote(opts)
    end
  end
end
