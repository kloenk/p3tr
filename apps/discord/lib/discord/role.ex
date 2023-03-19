defmodule Discord.Role do
  import Nostrum.Snowflake, only: [is_snowflake: 1]

  @callback store_role(module(), Nostrum.Snowflake.t(), Nostrum.Snowflake.t()) ::
              :ok
              | {:error, term()}
  @callback delete_role(Nostrum.Snowflake.t(), Nostrum.Snowflake.t()) :: :ok | {:error, term()}

  @doc """
  Creates a role with the given name and options.
  """
  def create_role(store_module, module \\ nil, guild, name, opts \\ [])

  def create_role(store_module, module, %Nostrum.Struct.Guild{id: guild}, name, opts) do
    create_role(store_module, module, guild, name, opts)
  end

  def create_role(store_module, module, guild, name, opts)
      when is_snowflake(guild) and is_binary(name) do
    opts =
      Keyword.put(opts, :name, name)
      |> Keyword.put(:managed, true)

    reason = get_reason_text(module)

    Nostrum.Api.create_guild_role(guild, opts, reason)
    |> IO.inspect(label: "create_role")
    |> case do
      {:ok, role} -> store_role(store_module, module, guild, role)
      v -> v
    end
  end

  defp store_role(store_module, module, guild, role)
       when is_integer(guild) and is_integer(role) do
    store_module.store_role(module, guild, role)
    |> case do
      :ok ->
        {:ok, role}

      {:ok, _} ->
        {:ok, role}

      {:error, e} ->
        Nostrum.Api.delete_guild_role!(guild, role)
        {:error, e}
    end
  end

  defp store_role(store_module, module, guild, %{id: role})
       when is_integer(guild) and is_integer(role) do
    store_role(store_module, module, guild, role)
  end

  def delete_role(store_module, guild, role, reason \\ nil) do
    Nostrum.Api.delete_guild_role(guild, role, reason)
    |> case do
      {:ok} -> store_module.delete_role(guild, role)
      v -> v
    end
  end

  def get_reason_text(module, mode \\ :create) do
    text =
      if Kernel.function_exported?(module, :role_reason, 1) do
        get_reason_function(module, mode)
      else
        get_reason_module(module)
      end

    # Gettext.dgettext(JllyBot.Gettext, "role", v)

    text
  end

  defp get_reason_function(module, mode) do
    module.role_reason(mode)
    |> case do
      nil -> get_reason_module(module)
      v -> v
    end
  end

  defp get_reason_module(nil), do: nil

  defp get_reason_module(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.downcase(:ascii)
  end

  # Generator
  @doc false
  def role_helpers(module) do
    quote do
      @spec create_role(module() | nil, Nostrum.Snowflake.t(), String.t(), Keyword.t()) ::
              {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, term()}
      def create_role(module \\ nil, guild, name, opts \\ []) do
        Discord.Role.create_role(unquote(module), module, guild, name, opts)
      end

      @spec delete_role(Nostrum.Snowflake.t(), Nostrum.Snowflake.t(), String.t() | nil) ::
              :ok | {:error, term()}
      def delete_role(guild, role, reason \\ nil) do
        Discord.Role.delete_role(unquote(module), guild, role, reason)
      end
    end
  end
end
