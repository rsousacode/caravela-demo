defmodule CaravelaDemo.Flows do
  @moduledoc """
  Catalog of demo flows for the Command Center's Flows panel.

  Each entry wraps a `Caravela.Flow`-declared module with the
  metadata the UI needs (title, description, accent, documented
  signals). Funs are not JSON-serializable — the UI ships signal
  *ids*, and `dispatch_signal/2` maps those back to state-mutating
  funs on the server side.
  """

  alias CaravelaDemo.Flows.{BookSyncFlow, DebounceFlow, ParallelFlow, RaceFlow, RetryFlow}

  @flows [
    %{
      id: "debounce",
      title: "Debounce",
      accent: "reef",
      description:
        "Coalesce burst signals into one run after 1s of state-stability. Mash the signal button — every press resets the timer.",
      module: DebounceFlow,
      flow_name: :tick,
      primitives: ~w(wait_until debounce run repeat),
      signals: [
        %{
          id: "signal",
          label: "Signal",
          hint: "Each press increments signal_count; timer resets"
        },
        %{
          id: "reset",
          label: "Reset tick",
          hint: "Zero the tick counter without restarting the flow"
        }
      ]
    },
    %{
      id: "retry",
      title: "Retry + backoff",
      accent: "ember",
      description:
        "A flaky upstream fails 85% of the time. The flow retries with exponential backoff (300 → 600 → 1200 ms) until success or max retries exhausted.",
      module: RetryFlow,
      flow_name: :fetch,
      primitives: ~w(run retry exponential),
      signals: []
    },
    %{
      id: "parallel",
      title: "Parallel fan-out",
      accent: "sail",
      description:
        "Three branches with different durations run concurrently. The flow continues when the slowest completes; results collected into state.fanout_results.",
      module: ParallelFlow,
      flow_name: :fanout,
      primitives: ~w(parallel timeout),
      signals: []
    },
    %{
      id: "race",
      title: "Race",
      accent: "sand",
      description:
        "Three branches start at once; first back wins, rest are cancelled. Re-run to see a different winner (durations are randomized).",
      module: RaceFlow,
      flow_name: :race,
      primitives: ~w(race timeout),
      signals: []
    },
    %{
      id: "book_sync",
      title: "Book sync",
      accent: "wave-400",
      description:
        "The canonical Caravela.Flow example — wait for dirty, debounce edits, sync, and loop. Toggle `dirty` from the signal panel to trigger a cycle.",
      module: BookSyncFlow,
      flow_name: :sync,
      primitives: ~w(wait_until debounce run repeat),
      signals: [
        %{
          id: "mark_dirty",
          label: "Mark dirty",
          hint: "Sets dirty: true — kicks the debounce window"
        },
        %{
          id: "set_book",
          label: "Rename book_id",
          hint: "Writes a random suffix into state.book_id"
        }
      ]
    }
  ]

  @doc "All catalog entries, UI-facing only (no closures)."
  def catalog, do: Enum.map(@flows, &public_view/1)

  @doc "Find a single catalog entry (with closures) by id."
  def fetch(id) when is_binary(id), do: Enum.find(@flows, &(&1.id == id))

  @doc """
  Map a `{flow_id, signal_id, payload}` triple to a state-mutating
  function. Returns nil if the pair is unknown.
  """
  def signal_fun("debounce", "signal", _), do: fn s -> %{s | signal_count: s.signal_count + 1} end
  def signal_fun("debounce", "reset", _), do: fn s -> %{s | tick: 0} end
  def signal_fun("book_sync", "mark_dirty", _), do: fn s -> %{s | dirty: true} end

  def signal_fun("book_sync", "set_book", _) do
    fn s -> %{s | book_id: "book-" <> random_suffix()} end
  end

  def signal_fun(_, _, _), do: nil

  defp public_view(entry) do
    Map.take(entry, [:id, :title, :accent, :description, :primitives, :signals])
    |> Map.put(:has_signals, entry.signals != [])
    |> Map.put(:module, inspect(entry.module))
    |> Map.put(:flow_name, to_string(entry.flow_name))
  end

  defp random_suffix do
    :crypto.strong_rand_bytes(3) |> Base.encode16(case: :lower)
  end
end
