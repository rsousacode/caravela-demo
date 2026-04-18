defmodule CaravelaDemo.Flows.RaceFlow do
  @moduledoc """
  Demonstrates `race` — three tasks start together, the first one to
  return wins and the others are cancelled.
  """

  use Caravela.Flow

  flow :race,
    initial_state: %{
      winner: nil,
      __step: "race"
    } do
    set_state(fn s -> %{s | __step: "race"} end)

    race(
      [
        fn ->
          ms = :rand.uniform(1500) + 200
          Process.sleep(ms)
          %{runner: "alpha", ms: ms}
        end,
        fn ->
          ms = :rand.uniform(1500) + 200
          Process.sleep(ms)
          %{runner: "beta", ms: ms}
        end,
        fn ->
          ms = :rand.uniform(1500) + 200
          Process.sleep(ms)
          %{runner: "gamma", ms: ms}
        end
      ],
      collect_as: :winner,
      timeout: 5_000
    )

    set_state(fn s -> %{s | __step: "done"} end)
  end
end
