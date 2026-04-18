defmodule CaravelaDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CaravelaDemo.Repo,
      {Phoenix.PubSub, name: CaravelaDemo.PubSub},
      {Registry, keys: :unique, name: CaravelaDemo.FlowRegistry},
      Caravela.Flow.Supervisor,
      CaravelaDemo.FlowController,
      CaravelaDemoWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CaravelaDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CaravelaDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
