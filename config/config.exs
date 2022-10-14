# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mintacoin,
  ecto_repos: [Mintacoin.Repo]

# Configures the endpoint
config :mintacoin, MintacoinWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: MintacoinWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Mintacoin.PubSub,
  live_view: [signing_salt: "zofbeibr"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban configuration
config :mintacoin, Oban,
  repo: Mintacoin.Repo,
  queues: [default: 2, create_account_queue: 2, create_asset_queue: 2]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
