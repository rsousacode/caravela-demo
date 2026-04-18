defmodule CaravelaDemoWeb.LiveRuntimePanel do
  @moduledoc """
  Pure functions that drive the Live Runtime Inspector panel.

  The panel walks an action's step list one at a time on a fixed
  cadence so stakeholders can see each updater in a composition fire
  against the domain's state. Updaters are resolved by name via
  `BookEditorDomain.__caravela_live_updater__/1` (the real framework
  lookup), applied with `Caravela.Live.Updater.run/2,3` semantics, and
  then the new state + a trace entry are returned to the LiveView.
  """

  alias CaravelaDemo.LiveRuntime.{ActionCatalog, BookEditorDomain}

  # --- Lifecycle --------------------------------------------------------

  @spec initial() :: map()
  def initial do
    state = BookEditorDomain.__caravela_live_state__()

    %{
      state: state,
      active_action: nil,
      step_index: nil,
      running: false,
      actions: ActionCatalog.catalog(),
      trace: [],
      step_delay: ActionCatalog.step_delay()
    }
  end

  @spec reset(map()) :: map()
  def reset(panel) do
    initial()
    |> Map.put(:trace, prepend_trace(panel.trace, "reset", "state cleared", %{}))
  end

  # --- Action lifecycle -------------------------------------------------

  @doc """
  Begin running an action. Returns `{panel, wait_ms}` — the caller
  schedules `:live_runtime_step` after `wait_ms` to fire step 0.
  Returns `nil` if the action id is unknown.
  """
  @spec start_action(map(), String.t()) :: {map(), non_neg_integer()} | nil
  def start_action(panel, action_id) do
    case ActionCatalog.fetch(action_id) do
      nil ->
        nil

      action ->
        panel =
          panel
          |> Map.put(:active_action, action.id)
          |> Map.put(:step_index, -1)
          |> Map.put(:running, true)
          |> prepend_trace_self(
            "action",
            "▶ " <> action.label <> " (#{length(action.steps)} steps)",
            %{}
          )

        # Fire the first step immediately.
        {panel, 0}
    end
  end

  @doc """
  Apply the step at `idx` of the currently-active action. Returns
  `{panel, next_delay_ms | :done}`.
  """
  @spec run_step(map(), non_neg_integer()) :: {map(), non_neg_integer() | :done}
  def run_step(%{active_action: nil} = panel, _idx), do: {panel, :done}

  def run_step(%{active_action: action_id} = panel, idx) do
    action = ActionCatalog.fetch(action_id)

    cond do
      action == nil ->
        {finish(panel), :done}

      idx >= length(action.steps) ->
        {finish(panel), :done}

      true ->
        step = Enum.at(action.steps, idx)
        {new_state, trace} = apply_step(panel.state, step)

        panel =
          panel
          |> Map.put(:state, new_state)
          |> Map.put(:step_index, idx)
          |> Map.put(:trace, [trace | panel.trace] |> Enum.take(40))

        next_idx = idx + 1

        if next_idx >= length(action.steps) do
          {finish(panel), :done}
        else
          {panel, next_delay(step, panel.step_delay)}
        end
    end
  end

  @doc "Stop the current action without running remaining steps."
  def stop(panel) do
    if panel.active_action do
      panel
      |> Map.put(:active_action, nil)
      |> Map.put(:step_index, nil)
      |> Map.put(:running, false)
      |> prepend_trace_self("action", "■ stopped", %{})
    else
      panel
    end
  end

  # --- Private helpers --------------------------------------------------

  defp apply_step(state, {:updater, name, args}) do
    fun = BookEditorDomain.__caravela_live_updater__(name)

    cond do
      is_nil(fun) ->
        {state,
         %{
           at: System.system_time(:millisecond),
           kind: "error",
           label: "updater",
           detail: "unknown updater: #{name}",
           diff: %{}
         }}

      true ->
        new_state = apply(fun, [state | args])
        diff = diff(state, new_state)

        {new_state,
         %{
           at: System.system_time(:millisecond),
           kind: "updater",
           label: to_string(name),
           detail: format_args(args),
           diff: diff
         }}
    end
  end

  defp apply_step(state, {:wait, ms}) do
    {state,
     %{
       at: System.system_time(:millisecond),
       kind: "wait",
       label: "wait",
       detail: "#{ms}ms",
       diff: %{}
     }}
  end

  defp next_delay({:wait, ms}, _), do: ms
  defp next_delay(_, cadence), do: cadence

  defp finish(panel) do
    panel
    |> Map.put(:active_action, nil)
    |> Map.put(:step_index, nil)
    |> Map.put(:running, false)
    |> prepend_trace_self("action", "✓ done", %{})
  end

  defp diff(before_state, after_state) do
    changed_keys =
      Map.keys(after_state)
      |> Enum.filter(fn k -> Map.get(before_state, k) != Map.get(after_state, k) end)

    Map.new(changed_keys, fn k ->
      {Atom.to_string(k),
       %{
         from: safe_preview(Map.get(before_state, k)),
         to: safe_preview(Map.get(after_state, k))
       }}
    end)
  end

  defp safe_preview(v) when is_binary(v), do: v
  defp safe_preview(v) when is_boolean(v) or is_nil(v) or is_number(v), do: v
  defp safe_preview(v) when is_atom(v), do: Atom.to_string(v)
  defp safe_preview(v) when is_list(v), do: "[#{length(v)}]"
  defp safe_preview(%{} = m) when not is_struct(m), do: "{#{map_size(m)}}"
  defp safe_preview(v), do: inspect(v, limit: 40)

  defp format_args([]), do: ""

  defp format_args(args) do
    args
    |> Enum.map(&inspect(&1, limit: 5, printable_limit: 40))
    |> Enum.join(", ")
  end

  defp prepend_trace_self(panel, kind, label, diff) do
    entry = %{
      at: System.system_time(:millisecond),
      kind: kind,
      label: label,
      detail: "",
      diff: diff
    }

    %{panel | trace: [entry | panel.trace] |> Enum.take(40)}
  end

  defp prepend_trace(trace, kind, detail, diff) do
    [
      %{
        at: System.system_time(:millisecond),
        kind: kind,
        label: kind,
        detail: detail,
        diff: diff
      }
      | trace
    ]
    |> Enum.take(40)
  end
end
