defmodule CaravelaDemo.LiveRuntime.ActionCatalog do
  @moduledoc """
  Pre-built updater compositions for the Live Runtime panel.

  Each action is an ordered list of steps the runner walks through one
  at a time with a short pause between, so the UI can highlight the
  currently-executing updater in the pipeline.

  Two kinds of steps:

    * `{:updater, name, args}` — resolve the updater by name against
      `BookEditorDomain` and apply it.
    * `{:wait, ms}` — no-op pause (used to make `mark_saving → sleep →
      mark_saved` cycles visible to stakeholders).

  The `pipeline` field is a flat list of label strings shown in the UI
  as the visual DAG — it mirrors the step list but renders steps
  differently (updaters get bold pills, waits get a dashed "gap" label).
  """

  @sample_book_a %{title: "The Phoenix Project", isbn: "9781942788294", price: "25.99"}
  @sample_book_b %{title: "Domain Modeling Made Functional", isbn: "9781680502541", price: "36.99"}

  @actions [
    %{
      id: "load",
      label: "Load book",
      accent: "wave-400",
      description:
        "Fetch a book from an imaginary backend. Resets dirty + validation_errors and shows a flash.",
      pipeline: [%{type: "updater", label: "load_book", arg: "sample_book"}],
      steps: [{:updater, :load_book, [@sample_book_a]}]
    },
    %{
      id: "edit_valid",
      label: "Edit title → validate",
      accent: "reef",
      description:
        "Two updaters composed: set_field(:title, \"…\") ~> validate. Classic Caravela.Live.Updater pattern.",
      pipeline: [
        %{type: "updater", label: "set_field(:title)", arg: "\"The Unicorn Project\""},
        %{type: "updater", label: "validate", arg: nil}
      ],
      steps: [
        {:updater, :set_field, [{:title, "The Unicorn Project"}]},
        {:updater, :validate, []}
      ]
    },
    %{
      id: "edit_invalid",
      label: "Edit title → validate (invalid)",
      accent: "coral",
      description:
        "Push a title that violates min_length. The validate updater populates validation_errors.",
      pipeline: [
        %{type: "updater", label: "set_field(:title)", arg: "\"ab\""},
        %{type: "updater", label: "validate", arg: nil}
      ],
      steps: [
        {:updater, :set_field, [{:title, "ab"}]},
        {:updater, :validate, []}
      ]
    },
    %{
      id: "save",
      label: "Save (mark_saving → … → mark_saved)",
      accent: "ember",
      description:
        "Full save flow: flip saving flag, simulate network, mark saved with timestamp, clear flash.",
      pipeline: [
        %{type: "updater", label: "mark_saving", arg: nil},
        %{type: "wait", label: "network", arg: "600ms"},
        %{type: "updater", label: "mark_saved", arg: nil},
        %{type: "wait", label: "flash visible", arg: "1500ms"},
        %{type: "updater", label: "clear_flash", arg: nil}
      ],
      steps: [
        {:updater, :mark_saving, []},
        {:wait, 600},
        {:updater, :mark_saved, []},
        {:wait, 1500},
        {:updater, :clear_flash, []}
      ]
    },
    %{
      id: "snapshot_edit",
      label: "Snapshot + edit price",
      accent: "sail",
      description:
        "Push current book onto history before mutating — foundation for undo/redo and optimistic updates.",
      pipeline: [
        %{type: "updater", label: "snapshot", arg: nil},
        %{type: "updater", label: "set_field(:price)", arg: "\"29.99\""}
      ],
      steps: [
        {:updater, :snapshot, []},
        {:updater, :set_field, [{:price, "29.99"}]}
      ]
    },
    %{
      id: "undo",
      label: "Undo",
      accent: "sand",
      description:
        "Pop the most recent snapshot from history back into book. Idempotent when history is empty.",
      pipeline: [%{type: "updater", label: "undo", arg: nil}],
      steps: [{:updater, :undo, []}]
    },
    %{
      id: "load_b",
      label: "Load a different book",
      accent: "wave-300",
      description: "Same load pattern with a different payload.",
      pipeline: [%{type: "updater", label: "load_book", arg: "sample_book_b"}],
      steps: [{:updater, :load_book, [@sample_book_b]}]
    }
  ]

  @step_delay 300

  @doc "Catalog view shipped to the UI — public fields only, no closures."
  def catalog, do: Enum.map(@actions, &Map.take(&1, [:id, :label, :accent, :description, :pipeline]))

  @doc "Fetch the full action (with steps) by id, or nil."
  def fetch(id), do: Enum.find(@actions, &(&1.id == id))

  @doc "Cadence between steps for regular updaters (ms)."
  def step_delay, do: @step_delay
end
