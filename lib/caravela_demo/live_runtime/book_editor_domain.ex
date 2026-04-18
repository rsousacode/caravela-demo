defmodule CaravelaDemo.LiveRuntime.BookEditorDomain do
  @moduledoc """
  Demo Live.Domain for the Live Runtime Inspector.

  Declares a small book-editor state plus named updaters — the kind of
  thing you'd reach for when a LiveView grows past a handful of
  ad-hoc `handle_event` clauses. Actions in `ActionCatalog` compose
  these updaters into named pipelines.
  """

  use Caravela.Live.Domain

  state do
    field :book, :map, default: %{title: "", isbn: "", price: nil}
    field :dirty, :boolean, default: false
    field :saving, :boolean, default: false
    field :validation_errors, :map, default: %{}
    field :last_saved_at, :string, default: nil
    field :flash_message, :string, default: nil
    field :history, :list, default: []
  end

  # --- Updaters ---------------------------------------------------------

  updater :load_book, fn s, book ->
    %{
      s
      | book: book,
        dirty: false,
        validation_errors: %{},
        last_saved_at: nil,
        flash_message: "Loaded"
    }
  end

  updater :set_field, fn s, {field, value} ->
    %{s | book: Map.put(s.book, field, value), dirty: true}
  end

  updater :validate, fn s ->
    errors =
      %{}
      |> validate_title(s.book)
      |> validate_isbn(s.book)

    %{s | validation_errors: errors}
  end

  updater :mark_saving, fn s ->
    %{s | saving: true, flash_message: nil}
  end

  updater :mark_saved, fn s ->
    %{
      s
      | saving: false,
        dirty: false,
        last_saved_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        flash_message: "Saved"
    }
  end

  updater :clear_flash, fn s ->
    %{s | flash_message: nil}
  end

  updater :snapshot, fn s ->
    %{s | history: [s.book | s.history] |> Enum.take(10)}
  end

  updater :undo, fn s ->
    case s.history do
      [prev | rest] ->
        %{s | book: prev, history: rest, dirty: true, flash_message: "Undid last edit"}

      _ ->
        %{s | flash_message: "Nothing to undo"}
    end
  end

  # --- Private helpers --------------------------------------------------

  defp validate_title(errors, %{title: title}) when is_binary(title) do
    cond do
      title == "" -> Map.put(errors, :title, "required")
      String.length(title) < 3 -> Map.put(errors, :title, "min 3 characters")
      true -> errors
    end
  end

  defp validate_title(errors, _), do: Map.put(errors, :title, "required")

  defp validate_isbn(errors, %{isbn: isbn}) when is_binary(isbn) and isbn != "" do
    if Regex.match?(~r/^\d{13}$/, isbn) do
      errors
    else
      Map.put(errors, :isbn, "must be 13 digits")
    end
  end

  defp validate_isbn(errors, _), do: errors
end
