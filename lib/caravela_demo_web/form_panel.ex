defmodule CaravelaDemoWeb.FormPanel do
  @moduledoc """
  Pure functions that drive the Forms playground panel.

  Owns the handful of state transitions invoked from `CommandCenterLive`:
  role switching, field edits, synchronous validation, async-validation
  kickoff and reply, save/reset, and round-trip logging. Each one takes
  the form-state map and returns an updated one — the LiveView just
  calls them and re-assigns.
  """

  alias CaravelaDemo.FormDomains.BookFormDomain

  @roles %{
    "anon" => {:anon, "Anonymous"},
    "editor" => {:editor, "Alice (editor)"},
    "admin" => {:admin, "Bob (admin)"}
  }

  @field_atoms ~w(title isbn published price publish_at)a

  # --- Lifecycle --------------------------------------------------------

  @spec initial() :: map()
  def initial do
    state = BookFormDomain.__caravela_live_state__()
    meta = BookFormDomain.__caravela_form__()

    state
    |> Map.put(:field_visibility, BookFormDomain.__caravela_form_visibility__(state))
    |> Map.put(:log, [])
    |> Map.put(
      :meta,
      %{
        visible_fields: Enum.map(meta.visible_fields, &Atom.to_string/1),
        async_fields: Enum.map(meta.async_fields, &Atom.to_string/1),
        debounces: Map.new(meta.debounces, fn {k, v} -> {Atom.to_string(k), v} end),
        entity: inspect(meta.entity)
      }
    )
    |> Map.put(:roles, roles_view())
  end

  @spec roles_view() :: [map()]
  def roles_view do
    Enum.map(@roles, fn {k, {_atom, name}} -> %{id: k, name: name} end)
    |> Enum.sort_by(fn %{id: id} ->
      case id do
        "anon" -> 0
        "editor" -> 1
        "admin" -> 2
        _ -> 3
      end
    end)
  end

  # --- Event handlers ---------------------------------------------------

  def set_role(form, role) when is_map_key(@roles, role) do
    {atom, name} = Map.fetch!(@roles, role)

    form
    |> Map.put(:current_user, %{role: atom, name: name})
    |> recompute_visibility()
    |> append_log("set_role", "role → #{role}")
  end

  def set_role(form, _), do: form

  def change_field(form, field, value) do
    case to_field(field) do
      nil ->
        form

      atom ->
        normalized = normalize(atom, value)
        attrs = Map.put(form.attrs, atom, normalized)

        form
        |> Map.put(:attrs, attrs)
        |> sync_validate(atom)
        |> recompute_visibility()
        |> append_log("change", "#{field} = #{inspect(normalized)}")
    end
  end

  def kickoff_async_validate(form, field, value) do
    case to_field(field) do
      atom when atom in [:isbn] ->
        form
        |> append_log("→ validate_async", "field=#{field} value=#{inspect(value)}")

      _ ->
        form
    end
  end

  def apply_async_result(form, field, value, result) do
    atom = to_field(field)

    cond do
      atom == nil ->
        form

      Map.get(form.attrs, atom) != value ->
        append_log(form, "… stale", "field=#{field} discarded")

      match?(:ok, result) ->
        form
        |> Map.put(:async_errors, Map.delete(form.async_errors, atom))
        |> append_log("← async ok", "field=#{field}")

      match?({:error, _}, result) ->
        {:error, msg} = result

        form
        |> Map.put(:async_errors, Map.put(form.async_errors, atom, msg))
        |> append_log("← async error", "field=#{field} · #{msg}")

      true ->
        form
    end
  end

  def save(form) do
    errors = sync_errors(form.attrs)

    cond do
      map_size(errors) > 0 ->
        form
        |> Map.put(:errors, errors)
        |> append_log("save", "rejected (#{map_size(errors)} sync errors)")

      map_size(form.async_errors) > 0 ->
        form
        |> append_log(
          "save",
          "rejected (async error on #{Map.keys(form.async_errors) |> Enum.map(&Atom.to_string/1) |> Enum.join(",")})"
        )

      true ->
        form
        |> Map.put(:saving, true)
        |> Map.put(:flash_message, nil)
        |> append_log("save", "submitted")
    end
  end

  def save_done(form) do
    form
    |> Map.put(:saving, false)
    |> Map.put(:flash_message, "Saved (simulated)")
    |> Map.put(:errors, %{})
    |> append_log("← save done", "ok")
  end

  def reset(form) do
    fresh = initial()

    fresh
    |> Map.put(:current_user, form.current_user)
    |> recompute_visibility()
    |> append_log("reset", "cleared attrs")
  end

  # --- Async dispatch (called with the current form assigns) -----------

  @spec run_async_validator(String.t(), any(), map()) :: :ok | {:error, String.t()}
  def run_async_validator(field, value, assigns) do
    case to_field(field) do
      nil -> :ok
      atom -> BookFormDomain.__caravela_form_validate_async__(atom, value, assigns)
    end
  end

  # --- Private ---------------------------------------------------------

  defp to_field(f) when is_binary(f) do
    if f in Enum.map(@field_atoms, &Atom.to_string/1), do: String.to_existing_atom(f), else: nil
  end

  defp to_field(f) when is_atom(f), do: f
  defp to_field(_), do: nil

  defp recompute_visibility(form) do
    Map.put(form, :field_visibility, BookFormDomain.__caravela_form_visibility__(form))
  end

  defp normalize(:published, v) when is_boolean(v), do: v
  defp normalize(:published, "true"), do: true
  defp normalize(:published, "false"), do: false
  defp normalize(:price, ""), do: nil
  defp normalize(:price, v) when is_binary(v), do: v
  defp normalize(:publish_at, ""), do: nil
  defp normalize(_, v), do: v

  # Same synchronous rules the Library domain enforces on :books
  defp sync_errors(attrs) do
    errors = %{}

    errors =
      cond do
        attrs.title in [nil, ""] -> Map.put(errors, :title, "required")
        String.length(attrs.title) < 3 -> Map.put(errors, :title, "min 3 characters")
        true -> errors
      end

    errors
  end

  defp sync_validate(form, :title) do
    case Map.get(form.attrs, :title) do
      v when v in [nil, ""] -> %{form | errors: Map.delete(form.errors, :title)}
      v when is_binary(v) and byte_size(v) < 3 ->
        %{form | errors: Map.put(form.errors, :title, "min 3 characters")}

      _ ->
        %{form | errors: Map.delete(form.errors, :title)}
    end
  end

  defp sync_validate(form, _), do: form

  defp append_log(form, label, detail) do
    entry = %{
      at: System.system_time(:millisecond),
      label: label,
      detail: detail
    }

    log = [entry | form.log] |> Enum.take(60)
    %{form | log: log}
  end
end
