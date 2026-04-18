defmodule CaravelaDemo.Flows.ParallelFlow do
  @moduledoc """
  Demonstrates `parallel` — three tasks with different durations run
  concurrently, collected together when the slowest finishes.
  """

  use Caravela.Flow

  flow :fanout,
    initial_state: %{
      fanout_results: nil,
      __step: "parallel"
    } do
    set_state(fn s -> %{s | __step: "parallel"} end)

    parallel(
      fn _state ->
        [
          fn ->
            Process.sleep(600)
            %{task: "fast", ms: 600}
          end,
          fn ->
            Process.sleep(1200)
            %{task: "medium", ms: 1200}
          end,
          fn ->
            Process.sleep(2000)
            %{task: "slow", ms: 2000}
          end
        ]
      end,
      collect_as: :fanout_results,
      timeout: 10_000
    )

    set_state(fn s -> %{s | __step: "done"} end)
  end
end
