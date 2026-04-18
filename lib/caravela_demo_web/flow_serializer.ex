defmodule CaravelaDemoWeb.FlowSerializer do
  @moduledoc """
  Turns a compiled `Caravela.Flow` step tree plus runner state into
  JSON-safe maps the Svelte layer can render.

  Each step gets a stable `id` (its path in the tree) so the UI can
  pulse the one whose name matches `state.__step`.
  """

  alias Caravela.Flow.Steps.{
    Debounce,
    Each,
    Parallel,
    Race,
    Repeat,
    Run,
    Sequence,
    SetState,
    Wait,
    WaitUntil
  }

  @doc "Walk a flow's step tree into a JSON-serializable node graph."
  def serialize_tree(flow_module, flow_name) do
    tree = flow_module.__caravela_flow__(flow_name)
    walk(tree, "root")
  end

  @doc "Serialize runner state into a JSON-safe map."
  def serialize_state(state) when is_map(state) do
    state
    |> Enum.reject(fn {k, _} -> k == :__struct__ end)
    |> Enum.map(fn {k, v} -> {to_string(k), jsonify(v)} end)
    |> Map.new()
  end

  def serialize_state(other), do: %{value: jsonify(other)}

  # --- Tree walking -----------------------------------------------------

  defp walk(%Sequence{steps: steps}, id) do
    %{
      id: id,
      type: "sequence",
      label: "sequence",
      children: children_ids(steps, id)
    }
  end

  defp walk(%Repeat{step: inner}, id) do
    %{
      id: id,
      type: "repeat",
      label: "repeat ∞",
      children: [walk(inner, id <> ".inner")]
    }
  end

  defp walk(%Wait{ms: ms}, id), do: leaf(id, "wait", "wait #{ms}ms", %{ms: ms})
  defp walk(%WaitUntil{}, id), do: leaf(id, "wait_until", "wait_until", %{})
  defp walk(%Debounce{ms: ms}, id), do: leaf(id, "debounce", "debounce #{ms}ms", %{ms: ms})
  defp walk(%SetState{}, id), do: leaf(id, "set_state", "set_state", %{})

  defp walk(%Run{retries: retries, backoff: backoff, base_delay: base}, id) do
    label =
      if retries > 0 do
        "run · retry ×#{retries} (#{backoff} @#{base}ms)"
      else
        "run"
      end

    leaf(id, "run", label, %{retries: retries, backoff: to_string(backoff), base_delay: base})
  end

  defp walk(%Parallel{collect_as: key, timeout: t}, id) do
    leaf(id, "parallel", "parallel → #{key}", %{collect_as: to_string(key), timeout: t})
  end

  defp walk(%Race{collect_as: key, timeout: t, tasks: tasks}, id) do
    leaf(id, "race", "race (#{length(tasks)}) → #{key}", %{
      collect_as: to_string(key),
      timeout: t,
      branches: length(tasks)
    })
  end

  defp walk(%Each{key: key}, id) do
    leaf(id, "each", "each :#{key}", %{key: to_string(key)})
  end

  defp walk(other, id) do
    leaf(id, "unknown", inspect(other), %{})
  end

  defp children_ids(steps, parent_id) do
    steps
    |> Enum.with_index()
    |> Enum.map(fn {step, i} -> walk(step, "#{parent_id}.#{i}") end)
  end

  defp leaf(id, type, label, opts) do
    %{id: id, type: type, label: label, opts: opts, children: []}
  end

  # --- State jsonification ---------------------------------------------

  defp jsonify(nil), do: nil
  defp jsonify(v) when is_boolean(v), do: v
  defp jsonify(v) when is_binary(v), do: v
  defp jsonify(v) when is_number(v), do: v
  defp jsonify(v) when is_atom(v), do: to_string(v)
  defp jsonify(v) when is_list(v), do: Enum.map(v, &jsonify/1)
  defp jsonify(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp jsonify(%{} = m) when not is_struct(m) do
    Map.new(m, fn {k, v} -> {to_string(k), jsonify(v)} end)
  end

  defp jsonify(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&jsonify/1)
  end

  defp jsonify(v), do: inspect(v)
end
