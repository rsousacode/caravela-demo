import Config

# The file-secret helper lets runtime config read Docker/Swarm secrets that
# are mounted at a path, e.g. DATABASE_URL_FILE=/run/secrets/database_url.
file_secret = fn name ->
  with path when is_binary(path) <- System.get_env(name <> "_FILE"),
       {:ok, contents} <- File.read(path) do
    String.trim(contents)
  else
    _ -> System.get_env(name)
  end
end

if System.get_env("PHX_SERVER") do
  config :caravela_demo, CaravelaDemoWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    file_secret.("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL (or DATABASE_URL_FILE) is missing.
      Example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []
  ssl_opts = if System.get_env("DATABASE_SSL") in ~w(true 1), do: [ssl: true], else: []

  config :caravela_demo,
         CaravelaDemo.Repo,
         [
           url: database_url,
           pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
           socket_options: maybe_ipv6
         ] ++ ssl_opts

  secret_key_base =
    file_secret.("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE (or SECRET_KEY_BASE_FILE) is missing.
      Generate one with: mix phx.gen.secret
      """

  host =
    System.get_env("PHX_HOST") ||
      raise "environment variable PHX_HOST is missing (public hostname, e.g. demo.example.com)"

  port = String.to_integer(System.get_env("PORT") || "4000")
  scheme = System.get_env("PHX_SCHEME") || "https"

  url_port =
    String.to_integer(
      System.get_env("PHX_URL_PORT") || if(scheme == "https", do: "443", else: "80")
    )

  config :caravela_demo, CaravelaDemoWeb.Endpoint,
    url: [host: host, port: url_port, scheme: scheme],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    check_origin: [scheme <> "://" <> host],
    secret_key_base: secret_key_base

  config :logger, level: String.to_atom(System.get_env("LOG_LEVEL") || "info")
end
