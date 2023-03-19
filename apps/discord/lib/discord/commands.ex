defmodule Discord.Commands do
  @doc """
  Execute a command
  """
  @callback command(String.t(), list(String.t()), %Nostrum.Struct.Interaction{}) ::
              :ok | {:ok, term()} | {:error, term()}

  @callback component(String.t(), list(String.t()), %Nostrum.Struct.Interaction{}) ::
              :ok | {:ok, term()} | {:error, term()}

  @doc false
  @callback global_commands() :: [Nostrum.Struct.ApplicationCommand.application_command_map()]

  @optional_callbacks component: 3

  # Macros
  defmacro __using__(opts) do
    quote do
      @behaviour unquote(__MODULE__)
      use Discord.Commands.Register, unquote(opts)
      use Discord.Commands.Interaction, unquote_splicing(opts)

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
