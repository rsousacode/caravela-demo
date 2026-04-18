defmodule CaravelaDemoWeb.VariantRunner do
  @moduledoc """
  Runs the three demo domain variants — baseline (single-tenant),
  multi-tenant, and multi-tenant + v2 — through the same generators
  so the Tenancy & Versions panel can show what the flags actually
  change in the emitted code.

  Output is shaped for the UI: per-variant DSL source, serialized IR,
  and a subset of generated files (the ones whose diff between
  variants is most pedagogically interesting — Ecto schema for
  `books`, migration, context, and a single REST controller).
  """

  alias CaravelaDemoWeb.{DomainSerializer, GeneratorRunner}

  @variants [
    %{
      id: "baseline",
      title: "Baseline",
      accent: "wave-400",
      module: CaravelaDemo.Domains.Library,
      source_path: "lib/caravela_demo/domains/library.ex",
      summary: "Single-tenant, unversioned. The default shape for a new app."
    },
    %{
      id: "multi_tenant",
      title: "+ multi-tenant",
      accent: "reef",
      module: CaravelaDemo.Domains.LibraryMultiTenant,
      source_path: "lib/caravela_demo/domains/library_multi_tenant.ex",
      summary:
        "Add `multi_tenant: true`. Caravela injects `tenant_id :binary_id` on every entity, scopes CRUD by the caller's tenant, and adds composite indexes."
    },
    %{
      id: "v2",
      title: "+ version v2",
      accent: "sail",
      module: CaravelaDemo.Domains.LibraryV2,
      source_path: "lib/caravela_demo/domains/library_v2.ex",
      summary:
        "Multi-tenant + `version \"v2\"`. Namespaces every generated module under `V2`, scopes routes under `/api/v2`, and lets multiple versions coexist. Also adds a demo field (`subtitle`) so the IR diff isn't purely metadata."
    }
  ]

  def all do
    Enum.map(@variants, &serialize/1)
  end

  # --- Private ---------------------------------------------------------

  defp serialize(variant) do
    domain = Caravela.domain!(variant.module)
    ir = DomainSerializer.serialize(domain)
    source = read_source(variant.source_path)
    files = generated_files(variant.module)

    variant
    |> Map.drop([:module, :source_path])
    |> Map.put(:source, source)
    |> Map.put(:ir, ir)
    |> Map.put(:files, files)
  end

  defp generated_files(module) do
    case GeneratorRunner.run_one("all", module) do
      nil -> []
      %{files: files} -> Enum.sort_by(files, & &1.path)
    end
  end

  defp read_source(relative) do
    path = Path.join(File.cwd!(), relative)

    case File.read(path) do
      {:ok, content} -> content
      _ -> "# source not found at #{relative}"
    end
  rescue
    _ -> "# source not found at #{relative}"
  end
end
