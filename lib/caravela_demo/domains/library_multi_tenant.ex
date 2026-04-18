defmodule CaravelaDemo.Domains.LibraryMultiTenant do
  @moduledoc """
  Same shape as `CaravelaDemo.Domains.Library` but declared with
  `multi_tenant: true`.

  Caravela auto-injects a `tenant_id :binary_id` field into every
  entity, wires it into migrations as a composite index, and the
  generated context scopes every CRUD call by the caller's
  `context.tenant.id`. Rendered side-by-side with the baseline on the
  Tenancy & Versions panel so stakeholders see exactly what the flag
  changes.
  """

  use Caravela.Domain, multi_tenant: true

  entity :authors do
    field :name, :string, required: true
    field :bio, :text
    field :born, :date
  end

  entity :books do
    field :title, :string, required: true, min_length: 3
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
