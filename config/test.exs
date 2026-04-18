import Config

config :caravela_demo, CaravelaDemo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  database: "caravela_demo_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :caravela_demo, CaravelaDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_replace_me_test_secret_replace_me_test_secret_replace_me",
  server: false

config :logger, level: :warning
