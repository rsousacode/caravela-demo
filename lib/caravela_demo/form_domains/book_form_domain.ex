defmodule CaravelaDemo.FormDomains.BookFormDomain do
  @moduledoc """
  Demo form-domain for `CaravelaDemo.Library.Book`.

  Two ways visibility is driven:

    * `:price` — gated by the current user's role (`:admin` or `:editor`
      only). A stakeholder toggles the role in the UI and the field
      literally disappears from the rendered form.
    * `:publish_at` — a virtual field (not on the Ecto schema) that
      appears only after the user flips `published` to true. Demonstrates
      how visibility can cascade off the form's own inputs, not just
      out-of-band context.

  And a single async validator:

    * `:isbn` — checks digit-only + length + ISBN-13 checksum server-side
      with a simulated 300ms network delay. The `debounce: 500` option
      is emitted as metadata so the client buffers keystrokes before
      pushing `validate_async`.
  """

  use Caravela.Live.Form,
    entity: CaravelaDemo.Library.Book,
    context_fields: [:current_user]

  state do
    field :attrs, :map,
      default: %{
        title: "",
        isbn: "",
        published: false,
        price: nil,
        publish_at: nil
      }

    field :errors, :map, default: %{}
    field :async_errors, :map, default: %{}
    field :field_visibility, :map, default: %{}
    field :saving, :boolean, default: false
    field :flash_message, :string, default: nil
    field :current_user, :map, default: %{role: :anon, name: "Anonymous"}
  end

  # --- Visibility predicates ---------------------------------------------

  visible :price, fn assigns ->
    role = get_in(assigns, [:current_user, :role])
    role in [:admin, :editor]
  end

  visible :publish_at, fn assigns ->
    Map.get(assigns.attrs || %{}, :published) == true
  end

  # --- Async validators --------------------------------------------------

  validate_async :isbn, [debounce: 500], fn value, _assigns ->
    # Simulate a real network hop so the spinner is visible.
    Process.sleep(300)

    cond do
      value in [nil, ""] ->
        :ok

      !Regex.match?(~r/^\d+$/, value) ->
        {:error, "digits only"}

      String.length(value) != 13 ->
        {:error, "must be 13 digits (got #{String.length(value)})"}

      !valid_isbn13_checksum?(value) ->
        {:error, "ISBN-13 checksum failed"}

      true ->
        :ok
    end
  end

  # --- Internal helpers --------------------------------------------------

  @doc """
  Standard ISBN-13 checksum: weight digits by 1,3,1,3,... and verify the
  sum mod 10 is zero. Public so the Svelte panel can reference a known
  valid example (9780262035613 — "An Introduction to Statistical Learning").
  """
  def valid_isbn13_checksum?(<<digits::binary-size(13)>>) do
    digits
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index()
    |> Enum.map(fn {d, i} -> if rem(i, 2) == 0, do: d, else: d * 3 end)
    |> Enum.sum()
    |> rem(10)
    |> Kernel.==(0)
  rescue
    _ -> false
  end

  def valid_isbn13_checksum?(_), do: false
end
