# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :p3tr,
  namespace: P3tr,
  ecto_repos: [P3tr.Repo]

config :p3tr, P3tr.Repo, pool_size: 10

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
config :p3tr, Discord.Commands.Register,
  gettext: P3tr.Gettext,
  allowed_langs: ~w(en de)

config :p3tr, Discord, modules: [P3tr.Discord.Pronoun]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
env =
  if Kernel.macro_exported?(Config, :config_env, 0) do
    Config.config_env()
  else
    Mix.env()
  end

import_config "#{env}.exs"

if File.exists?("./config/#{env}.secrets.exs") do
  import_config("#{env}.secrets.exs")
end

config :p3tr, env: env
