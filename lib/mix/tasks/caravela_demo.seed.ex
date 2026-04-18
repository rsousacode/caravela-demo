defmodule Mix.Tasks.CaravelaDemo.Seed do
  @shortdoc "Seed the demo database with publishers, authors, and books"

  @moduledoc """
  Populate the Library tables with enough data to make the generated
  CRUD UI interesting out of the box. Idempotent — running twice just
  inserts another round (rows are uniqued by primary key, not title).

      mix caravela_demo.seed

  To start clean: `mix ecto.reset && mix caravela_demo.seed`.
  """

  use Mix.Task

  alias CaravelaDemo.Library
  alias CaravelaDemo.Library.{Author, Book, Publisher}
  alias CaravelaDemo.Repo

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")

    if Repo.aggregate(Book, :count) > 0 do
      Mix.shell().info("Library already has rows. Skipping. Run `mix ecto.reset` first to reseed.")
    else
      do_seed()
    end
  end

  defp do_seed do
    Mix.shell().info("Seeding publishers…")

    publishers =
      for attrs <- [
            %{name: "MIT Press", country: "USA"},
            %{name: "O'Reilly Media", country: "USA"},
            %{name: "No Starch Press", country: "USA"},
            %{name: "Pragmatic Bookshelf", country: "USA"}
          ] do
        {:ok, %Publisher{} = p} = Library.create_publisher(attrs, %{})
        Mix.shell().info("  + publisher: #{p.name}")
        p
      end

    [mit, oreilly, nostarch, pragprog] = publishers

    Mix.shell().info("\nSeeding authors…")

    authors =
      for attrs <- [
            %{name: "Gene Kim", bio: "Tech researcher and author of The Phoenix Project.", born: ~D[1971-01-01]},
            %{name: "Dave Thomas", bio: "Co-founder of The Pragmatic Bookshelf.", born: ~D[1956-01-01]},
            %{name: "Ada Lovelace", bio: "Mathematician and first programmer.", born: ~D[1815-12-10]},
            %{name: "Scott Wlaschin", bio: "F# MVP and DDD advocate.", born: ~D[1965-01-01]}
          ] do
        {:ok, %Author{} = a} = Library.create_author(attrs, %{})
        Mix.shell().info("  + author: #{a.name}")
        a
      end

    Mix.shell().info("\nSeeding books…")

    book_rows = [
      {%{title: "The Phoenix Project", isbn: "9781942788294", published: true, price: Decimal.new("25.99")}, pragprog},
      {%{title: "The Unicorn Project", isbn: "9781942788768", published: true, price: Decimal.new("27.99")}, pragprog},
      {%{title: "Domain Modeling Made Functional", isbn: "9781680502541", published: true, price: Decimal.new("36.99")}, pragprog},
      {%{title: "Programming Elixir", isbn: "9781680502992", published: true, price: Decimal.new("42.99")}, pragprog},
      {%{title: "Designing Data-Intensive Applications", isbn: "9781449373320", published: true, price: Decimal.new("59.99")}, oreilly},
      {%{title: "SICP", isbn: "9780262510875", published: true, price: Decimal.new("70.00")}, mit},
      {%{title: "Eloquent JavaScript", isbn: "9781593279509", published: true, price: Decimal.new("39.95")}, nostarch},
      {%{title: "Upcoming Book", isbn: "9780000000000", published: false, price: nil}, pragprog}
    ]

    for {attrs, publisher} <- book_rows do
      attrs = Map.put(attrs, :publisher_id, publisher.id)
      {:ok, %Book{} = b} = Library.create_book(attrs, %{})
      Mix.shell().info("  + book: #{b.title}")
    end

    _ = authors

    Mix.shell().info("\nDone. Open http://localhost:4000/library/books")
  end
end
