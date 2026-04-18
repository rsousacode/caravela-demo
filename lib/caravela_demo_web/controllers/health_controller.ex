defmodule CaravelaDemoWeb.HealthController do
  use CaravelaDemoWeb, :controller

  @doc """
  Liveness: the VM answers, the endpoint is up. No DB check so a slow/unhealthy
  database doesn't knock the app out of its load balancer.
  """
  def live(conn, _params) do
    send_resp(conn, 200, "ok")
  end

  @doc """
  Readiness: also pings the Repo. Swarm / k8s should wait for this before
  routing traffic after a deploy.
  """
  def ready(conn, _params) do
    case Ecto.Adapters.SQL.query(CaravelaDemo.Repo, "SELECT 1", [], timeout: 2_000) do
      {:ok, _} -> send_resp(conn, 200, "ok")
      {:error, _} -> send_resp(conn, 503, "not ready")
    end
  end
end
