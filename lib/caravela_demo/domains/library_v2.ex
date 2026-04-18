defmodule CaravelaDemo.Domains.LibraryV2 do
  @moduledoc """
  Multi-tenant Library with an explicit API version.

  Caravela namespaces every generated module under `V2` (e.g.
  `CaravelaDemoWeb.V2.BookController`), scopes every REST route under
  `/api/v2`, and every GraphQL schema lives under `LibraryV2.Mutations`.
  Letting multiple versions coexist is the reason for the versioning
  flag — once a breaking change ships, copy this module to
  `LibraryV3`, bump the `version`, evolve the schema, and the V2
  clients keep talking to the V2 routes untouched.

  Also adds a demo-only field on `:books` (`subtitle`) so the IR diff
  against the baseline isn't purely metadata.
  """

  use Caravela.Domain, multi_tenant: true

  version "v2"

  entity :authors do
    field :name, :string, required: true
    field :bio, :text
    field :born, :date
  end

  entity :books do
    field :title, :string, required: true, min_length: 3
    field :subtitle, :string
    field :isbn, :string, format: ~r/^\d{13}$/
    field :published, :boolean, default: false
    field :price, :decimal, precision: 10, scale: 2
  end

  entity :publishers do
    field :name, :string, required: true
    field :country, :string
  end

  relation :authors, :books, type: :has_many
  relation :books, :publishers, type: :belongs_to
end
