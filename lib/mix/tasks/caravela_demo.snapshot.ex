defmodule Mix.Tasks.CaravelaDemo.Snapshot do
  @shortdoc "Capture baseline snapshots of every generator's output"

  @moduledoc """
  Runs every `mix caravela.gen.*` generator against the demo Library
  domain and writes the output to `priv/generator_snapshots/<id>.json`.

  The Command Center's Generators panel diffs the live output against
  these committed snapshots — regenerate them whenever you want to
  reset the baseline (for instance after intentionally changing the
  domain or the framework's templates).

      mix caravela_demo.snapshot
  """

  use Mix.Task

  alias CaravelaDemoWeb.{GeneratorRunner, GeneratorSnapshot}

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")

    gens = GeneratorRunner.run_all(CaravelaDemo.Domains.Library)

    Enum.each(gens, fn g ->
      :ok = GeneratorSnapshot.write(g.id, g.files)
      Mix.shell().info("  #{g.id} · #{g.file_count} files")
    end)

    Mix.shell().info("\nSnapshots written to priv/generator_snapshots/")
  end
end
