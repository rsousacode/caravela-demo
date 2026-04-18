defmodule CaravelaDemo.Flows.DebounceFlow do
  @moduledoc """
  Demonstrates `debounce` — coalescing burst signals into a single run
  after a period of state-stability.

  Mash the "signal" button — every press resets the 1000ms debounce
  timer. One tick fires after the dust settles.
  """

  use Caravela.Flow

  flow :tick,
    initial_state: %{
      signal_count: 0,
      tick: 0,
      __step: "wait_until"
    } do
    repeat do
      set_state(fn s -> %{s | __step: "wait_until"} end)
      wait_until(fn s -> s.signal_count > 0 end)

      set_state(fn s -> %{s | __step: "debounce"} end)
      debounce(1000)

      set_state(fn s -> %{s | __step: "run"} end)

      run(fn s ->
        {:ok, %{s | tick: s.tick + 1, signal_count: 0, __step: "wait_until"}}
      end)
    end
  end
end
