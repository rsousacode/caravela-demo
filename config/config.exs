import Config

config :caravela_demo,
  ecto_repos: [CaravelaDemo.Repo],
  generators: [binary_id: true]

config :caravela_demo, CaravelaDemo.Repo,
  migration_primary_key: [type: :binary_id],
  migration_foreign_key: [type: :binary_id]

config :caravela_demo, CaravelaDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CaravelaDemoWeb.ErrorHTML, json: CaravelaDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CaravelaDemo.PubSub,
  live_view: [signing_salt: "kM7Hq2yA"]

config :phoenix, :json_library, Jason

config :live_svelte,
  ssr: false

import_config "#{config_env()}.exs"
