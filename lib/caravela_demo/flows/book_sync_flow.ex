defmodule CaravelaDemo.Flows.BookSyncFlow do
  @moduledoc """
  The canonical Caravela Flow example: wait for an entity to become
  dirty, debounce edits, run an async sync, and loop.

  This is what the framework's README shows as the motivating case.
  """

  use Caravela.Flow

  flow :sync,
    initial_state: %{
      book_id: "book-abc",
      dirty: false,
      synced_count: 0,
      last_synced_at: nil,
      __step: "wait_until"
    } do
    repeat do
      set_state(fn s -> %{s | __step: "wait_until"} end)
      wait_until(fn s -> s.dirty end)

      set_state(fn s -> %{s | __step: "debounce"} end)
      debounce(800)

      set_state(fn s -> %{s | __step: "run"} end)

      run(fn s ->
        # Simulate hitting an external API.
        Process.sleep(400)

        {:ok,
         %{
           s
           | dirty: false,
             synced_count: s.synced_count + 1,
             last_synced_at: DateTime.utc_now() |> DateTime.to_iso8601(),
             __step: "wait_until"
         }}
      end)
    end
  end
end
