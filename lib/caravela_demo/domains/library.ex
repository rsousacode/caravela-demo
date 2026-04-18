defmodule CaravelaDemo.Domains.Library do
  @moduledoc """
  Library domain — the canonical Caravela demo.

  Declares authors, books, and publishers with relations between them.
  After changing this module, regenerate schemas with:

      mix caravela.gen.schema CaravelaDemo.Domains.Library
  """

  use Caravela.Domain

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
