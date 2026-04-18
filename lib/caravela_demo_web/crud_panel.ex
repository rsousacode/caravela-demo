defmodule CaravelaDemoWeb.CrudPanel do
  @moduledoc """
  Sidebar data for the Command Center's CRUD panel.

  Reports the row count per Library entity and links to the generated
  LiveView routes so stakeholders can jump from the Domain / Generators
  story into the real, running CRUD pages produced by
  `mix caravela.gen.live --with-domain CaravelaDemo.Domains.Library`.
  """

  alias CaravelaDemo.Library
  alias CaravelaDemo.Library.{Author, Book, Publisher}
  alias CaravelaDemo.Repo

  @ctx %{}

  @entities [
    %{
      id: "books",
      label: "Books",
      accent: "wave-400",
      schema: Book,
      sample_keys: [:title, :isbn, :published, :price],
      description:
        "Every event on these pages round-trips through the generated Phoenix context + FormDomain updaters. Edit a row and watch the `validate` / `save` events arrive in the server logs."
    },
    %{
      id: "authors",
      label: "Authors",
      accent: "sail",
      schema: Author,
      sample_keys: [:name, :born],
      description: "Has-many relation target for books."
    },
    %{
      id: "publishers",
      label: "Publishers",
      accent: "reef",
      schema: Publisher,
      sample_keys: [:name, :country],
      description: "Belongs-to relation target for books."
    }
  ]

  def initial do
    %{
      entities: Enum.map(@entities, &public_view/1),
      base_path: "/library"
    }
  end

  # --- Private ---------------------------------------------------------

  defp public_view(entity) do
    count = Repo.aggregate(entity.schema, :count)

    entity
    |> Map.drop([:schema, :sample_keys])
    |> Map.put(:count, count)
    |> Map.put(:sample, recent_rows(entity))
    |> Map.put(:module, inspect(entity.schema))
  end

  defp recent_rows(%{id: "books", sample_keys: keys}) do
    Library.list_books(@ctx)
    |> Enum.take(6)
    |> Enum.map(fn b -> row(b, keys, "books") end)
  end

  defp recent_rows(%{id: "authors", sample_keys: keys}) do
    Library.list_authors(@ctx)
    |> Enum.take(6)
    |> Enum.map(fn a -> row(a, keys, "authors") end)
  end

  defp recent_rows(%{id: "publishers", sample_keys: keys}) do
    Library.list_publishers(@ctx)
    |> Enum.take(6)
    |> Enum.map(fn p -> row(p, keys, "publishers") end)
  end

  defp row(struct, keys, path) do
    fields = Map.new(keys, fn k -> {Atom.to_string(k), render(Map.get(struct, k))} end)

    %{
      id: struct.id,
      fields: fields,
      path: "/library/#{path}/#{struct.id}",
      edit_path: "/library/#{path}/#{struct.id}/edit"
    }
  end

  defp render(nil), do: nil
  defp render(%Decimal{} = d), do: Decimal.to_string(d)
  defp render(%Date{} = d), do: Date.to_iso8601(d)
  defp render(%DateTime{} = d), do: DateTime.to_iso8601(d)
  defp render(v) when is_boolean(v) or is_binary(v) or is_number(v), do: v
  defp render(v), do: inspect(v)
end
