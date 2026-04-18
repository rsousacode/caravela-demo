defmodule CaravelaDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :caravela_demo,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {CaravelaDemo.Application, []}
    ]
  end

  defp caravela_dep do
    case System.get_env("CARAVELA_PATH") do
      nil -> {:caravela, "~> 0.5.3"}
      path -> {:caravela, path: path}
    end
  end

  defp deps do
    [
      caravela_dep(),
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:live_svelte, "~> 0.17"},
      {:bandit, "~> 1.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets npm run build"],
      "assets.deploy": ["cmd --cd assets npm run build", "phx.digest"]
    ]
  end

  defp releases do
    [
      caravela_demo: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
