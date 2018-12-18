# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :project4,
  ecto_repos: [Project4.Repo]

# Configures the endpoint
config :project4, Project4Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "t5d/u2HQZmVGUx3NAGNYdQY1kr+l2C9BXKR84FcqnqyCTPPlt9rhfLv9ljUM7EWw",
  render_errors: [view: Project4Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Project4.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
