defmodule Discord.Commands do
  @doc """
  Execute a command
  """
  @callback command(String.t(), list(String.t()), %Nostrum.Struct.Interaction{}) ::
              :ok | {:error, term()}

  @doc false
  @callback global_commands() :: [Nostrum.Struct.ApplicationCommand.application_command_map()]

  # Macros
  defmacro __using__(opts) do
    quote do
      @behaviour unquote(__MODULE__)
      use Discord.Commands.Register, unquote(opts)

      alias unquote(__MODULE__)
    end
  end

  def get(%Nostrum.Struct.ApplicationCommandInteractionDataOption{
        value: value
      }) do
    value
  end

  def get(args, name, default \\ nil) do
    fetch(args, name)
    |> case do
      {:ok, v} -> v
      :error -> default
    end
  end

  def fetch(args, name) do
    args
    |> Map.get(name)
    |> case do
      nil -> :error
      v -> {:ok, get(v)}
    end
  end

  def fetch!(args, name) do
    args
    |> Map.fetch!(name)
    |> get()
  end
end
