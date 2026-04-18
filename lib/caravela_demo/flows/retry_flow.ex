defmodule CaravelaDemo.Flows.RetryFlow do
  @moduledoc """
  Demonstrates `run` with retries and exponential backoff.

  A synthetic flaky upstream fails the first few attempts and
  eventually succeeds. Each retry doubles the delay. The flow
  completes (not repeats) so the Done/Error states are visible.
  """

  use Caravela.Flow

  flow :fetch,
    initial_state: %{
      attempts: 0,
      last_error: nil,
      result: nil,
      __step: "run"
    } do
    set_state(fn s -> %{s | __step: "run"} end)

    run(
      fn s ->
        attempt = s.attempts + 1

        if attempt < 4 and :rand.uniform() < 0.85 do
          {:retry,
           %{s | attempts: attempt, last_error: "503 upstream (attempt #{attempt})"}}
        else
          {:ok,
           %{
             s
             | attempts: attempt,
               result: "synced ok on attempt #{attempt}",
               __step: "done"
           }}
        end
      end,
      retries: 5,
      backoff: :exponential,
      base_delay: 300
    )
  end
end
