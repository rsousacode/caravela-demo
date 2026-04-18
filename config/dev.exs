import Config

config :caravela_demo, CaravelaDemo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  database: "caravela_demo_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :caravela_demo, CaravelaDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_replace_me_dev_secret_replace_me_dev_secret_replace_me_dev",
  watchers: [
    npm: ["run", "dev", cd: Path.expand("../assets", __DIR__)]
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/caravela_demo_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :caravela_demo, dev_routes: true

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :debug
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
