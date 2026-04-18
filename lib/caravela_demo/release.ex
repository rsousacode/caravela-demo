defmodule CaravelaDemo.Release do
  @moduledoc """
  Release tasks invoked from `bin/caravela_demo eval` inside a Mix release.

  The compiled release has no Mix, so ecto tasks like `mix ecto.migrate` are
  unavailable. Call these functions instead:

      bin/caravela_demo eval "CaravelaDemo.Release.migrate()"
      bin/caravela_demo eval "CaravelaDemo.Release.rollback(CaravelaDemo.Repo, 0)"
  """

  @app :caravela_demo

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
