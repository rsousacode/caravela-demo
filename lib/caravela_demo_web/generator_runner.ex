defmodule CaravelaDemoWeb.GeneratorRunner do
  @moduledoc """
  Drives Caravela's code generators directly for the demo UI.

  Each `mix caravela.gen.*` task is backed by a set of pure
  `render_all/render/render_entity` functions in `Caravela.Gen.*` that
  return `{path, content}` tuples without touching the filesystem. This
  module calls those functions and normalizes their output into a shape
  the Svelte layer can consume.

  Because every render is pure, we can safely call it on demand
  regardless of deployment — no `System.cmd`, no file mutations, no
  recompiler races. For stakeholder-facing deploys we also persist a
  baseline snapshot to `priv/generator_snapshots/` so the UI can diff
  the live output against a committed reference.
  """

  alias Caravela.Schema.Domain

  alias Caravela.Gen.{
    Context,
    Controller,
    EctoSchema,
    GraphQL,
    LiveView,
    Migration,
    Svelte
  }

  @type file :: %{path: String.t(), content: String.t(), language: String.t()}
  @type generator :: %{
          id: String.t(),
          task: String.t(),
          description: String.t(),
          category: String.t(),
          files: [file()]
        }

  @generators [
    %{
      id: "schema",
      task: "mix caravela.gen.schema",
      description: "Ecto schemas and migration — one schema per entity plus a timestamped migration.",
      category: "persistence"
    },
    %{
      id: "context",
      task: "mix caravela.gen.context",
      description: "Phoenix context module with CRUD functions, lifecycle hooks, and permission checks.",
      category: "persistence"
    },
    %{
      id: "api",
      task: "mix caravela.gen.api",
      description: "JSON REST controllers (one per entity) with index/show/create/update/delete actions.",
      category: "api"
    },
    %{
      id: "graphql",
      task: "mix caravela.gen.graphql",
      description: "Absinthe type definitions, queries, and mutations ready to mount into a schema.",
      category: "api"
    },
    %{
      id: "live",
      task: "mix caravela.gen.live",
      description: "LiveView index/show/form, typed Svelte components, and a TypeScript type file.",
      category: "ui"
    },
    %{
      id: "all",
      task: "mix caravela.gen",
      description: "Everything the per-layer generators produce — schemas, context, REST, GraphQL, LiveViews, and Svelte.",
      category: "meta"
    }
  ]

  @doc "Run every generator against the given domain module."
  @spec run_all(module()) :: [generator()]
  def run_all(domain_module) when is_atom(domain_module) do
    domain = Caravela.domain!(domain_module)
    Enum.map(@generators, &run(&1, domain))
  end

  @doc "Run a single generator by id against the given domain module."
  @spec run_one(String.t(), module()) :: generator() | nil
  def run_one(id, domain_module) when is_binary(id) and is_atom(domain_module) do
    case Enum.find(@generators, &(&1.id == id)) do
      nil -> nil
      meta -> run(meta, Caravela.domain!(domain_module))
    end
  end

  @doc "Static metadata about every generator (no rendering)."
  @spec generators() :: [map()]
  def generators, do: @generators

  # --- Runners ----------------------------------------------------------

  # Pin the migration timestamp so snapshots stay deterministic.
  # Real `mix caravela.gen.schema` uses the current UTC time — we
  # don't need that here because we diff against a committed baseline.
  @pinned_timestamp "00000000000000"

  defp run(%{id: "schema"} = meta, %Domain{} = domain) do
    files =
      [Migration.render(domain, timestamp: @pinned_timestamp) | EctoSchema.render_all(domain)]
      |> normalize_files()

    put_files(meta, files)
  end

  defp run(%{id: "context"} = meta, %Domain{} = domain) do
    put_files(meta, normalize_files([Context.render(domain)]))
  end

  defp run(%{id: "api"} = meta, %Domain{} = domain) do
    put_files(meta, normalize_files(Controller.render_all(domain)))
  end

  defp run(%{id: "graphql"} = meta, %Domain{} = domain) do
    put_files(meta, normalize_files(GraphQL.render_all(domain)))
  end

  defp run(%{id: "live"} = meta, %Domain{} = domain) do
    live_files = LiveView.render_all(domain)
    svelte_files = Svelte.render_all(domain)
    put_files(meta, normalize_files(live_files ++ svelte_files))
  end

  defp run(%{id: "all"} = meta, %Domain{} = domain) do
    files =
      [Migration.render(domain, timestamp: @pinned_timestamp)]
      |> Kernel.++(EctoSchema.render_all(domain))
      |> Kernel.++([Context.render(domain)])
      |> Kernel.++(Controller.render_all(domain))
      |> Kernel.++(GraphQL.render_all(domain))
      |> Kernel.++(LiveView.render_all(domain))
      |> Kernel.++(Svelte.render_all(domain))
      |> normalize_files()

    put_files(meta, files)
  end

  # --- Normalization ----------------------------------------------------

  defp put_files(meta, files) do
    Map.merge(meta, %{files: files, file_count: length(files)})
  end

  defp normalize_files(list) do
    list
    |> List.flatten()
    |> Enum.map(fn
      {path, content} when is_binary(path) and is_binary(content) ->
        %{path: path, content: content, language: language_for(path), bytes: byte_size(content)}
    end)
    |> Enum.sort_by(& &1.path)
  end

  defp language_for(path) do
    cond do
      String.ends_with?(path, ".ex") -> "elixir"
      String.ends_with?(path, ".exs") -> "elixir"
      String.ends_with?(path, ".heex") -> "elixir"
      String.ends_with?(path, ".svelte") -> "svelte"
      String.ends_with?(path, ".ts") -> "typescript"
      String.ends_with?(path, ".js") -> "javascript"
      String.ends_with?(path, ".json") -> "json"
      true -> "text"
    end
  end
end
