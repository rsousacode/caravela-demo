defmodule CaravelaDemo.FlowController do
  @moduledoc """
  Orchestrates demo flow lifecycle on behalf of LiveView subscribers.

  Each runner is told to notify a tiny per-flow forwarder process,
  which re-emits every message to this GenServer tagged with the
  flow id. That way we can fan out `{:flow_update, flow_id, _}`
  events to subscribers without having to guess who sent what.

  Flows survive LiveView navigation and page reload — subscribers
  can reattach by calling `subscribe/1`. The controller monitors
  every runner and cleans up when it terminates.
  """

  use GenServer

  alias Caravela.Flow
  alias CaravelaDemo.Flows

  @name __MODULE__

  # --- Client API -------------------------------------------------------

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @doc """
  Start (or restart) a flow by catalog id. Any previous instance of
  the same flow is terminated first — at most one runner per id.
  """
  def start(flow_id), do: GenServer.call(@name, {:start, flow_id})

  @doc "Stop a running flow by catalog id."
  def stop_flow(flow_id), do: GenServer.call(@name, {:stop, flow_id})

  @doc "Send a signal (catalog signal id) to the running flow."
  def signal(flow_id, signal_id, payload \\ %{}),
    do: GenServer.call(@name, {:signal, flow_id, signal_id, payload})

  @doc "Subscribe the caller to updates for `flow_id`."
  def subscribe(flow_id), do: GenServer.call(@name, {:subscribe, flow_id, self()})

  @doc "Unsubscribe the caller from updates for `flow_id`."
  def unsubscribe(flow_id), do: GenServer.cast(@name, {:unsubscribe, flow_id, self()})

  @doc """
  Snapshot of every running flow, keyed by flow_id. Used on LiveView
  mount to re-hydrate the UI after a reload.
  """
  def running, do: GenServer.call(@name, :running)

  # --- Server callbacks -------------------------------------------------

  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)

    {:ok,
     %{
       # flow_id => %{pid, forwarder, started_at, state, status}
       runners: %{},
       # flow_id => [subscriber_pid]
       subs: %{},
       # monitor_ref => {:runner | :sub, flow_id_or_nil}
       monitors: %{}
     }}
  end

  @impl true
  def handle_call({:start, flow_id}, _from, state) do
    case Flows.fetch(flow_id) do
      nil ->
        {:reply, {:error, :unknown_flow}, state}

      entry ->
        state = terminate_existing(state, flow_id)

        controller = self()
        forwarder = spawn(fn -> forward_loop(controller, flow_id) end)

        case Flow.start(entry.module, entry.flow_name, notify: forwarder) do
          {:ok, pid} ->
            ref = Process.monitor(pid)
            started_at = System.system_time(:millisecond)
            initial_state = entry.module.__caravela_flow_initial_state__(entry.flow_name)

            runner = %{
              pid: pid,
              forwarder: forwarder,
              started_at: started_at,
              state: initial_state,
              status: :running
            }

            state =
              state
              |> put_in([:runners, flow_id], runner)
              |> put_in([:monitors, ref], {:runner, flow_id})

            broadcast(flow_id, state, {:started,
              %{started_at: started_at, state: initial_state, status: "running"}})

            {:reply, {:ok, pid}, state}

          {:error, reason} ->
            if Process.alive?(forwarder), do: Process.exit(forwarder, :kill)
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:stop, flow_id}, _from, state) do
    case Map.get(state.runners, flow_id) do
      nil ->
        {:reply, :not_running, state}

      %{pid: pid} ->
        Flow.stop(pid)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:signal, flow_id, signal_id, payload}, _from, state) do
    with %{pid: pid} <- Map.get(state.runners, flow_id),
         fun when not is_nil(fun) <- Flows.signal_fun(flow_id, signal_id, payload) do
      Flow.signal(pid, fun)
      {:reply, :ok, state}
    else
      nil -> {:reply, {:error, :not_running}, state}
      _ -> {:reply, {:error, :unknown_signal}, state}
    end
  end

  @impl true
  def handle_call({:subscribe, flow_id, pid}, _from, state) do
    ref = Process.monitor(pid)

    state =
      state
      |> update_in([:subs, flow_id], fn
        nil -> [pid]
        list -> [pid | list] |> Enum.uniq()
      end)
      |> put_in([:monitors, ref], {:sub, nil})

    snapshot = snapshot_of(state, flow_id)
    {:reply, snapshot, state}
  end

  @impl true
  def handle_call(:running, _from, state) do
    view =
      Map.new(state.runners, fn {id, r} ->
        {id,
         %{
           started_at: r.started_at,
           state: r.state,
           status: Atom.to_string(r.status)
         }}
      end)

    {:reply, view, state}
  end

  @impl true
  def handle_cast({:unsubscribe, flow_id, pid}, state) do
    state =
      update_in(state, [:subs, flow_id], fn
        nil -> []
        list -> Enum.reject(list, &(&1 == pid))
      end)

    {:noreply, state}
  end

  # --- Forwarder-tagged notifications ----------------------------------

  @impl true
  def handle_info({:from_flow, flow_id, {:flow_state, new_state}}, state) do
    case Map.fetch(state.runners, flow_id) do
      {:ok, _} ->
        state = update_in(state, [:runners, flow_id], &%{&1 | state: new_state})
        broadcast(flow_id, state, {:state, new_state})
        {:noreply, state}

      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:from_flow, flow_id, {:flow_done, final_state}}, state) do
    case Map.fetch(state.runners, flow_id) do
      {:ok, _} ->
        state =
          update_in(state, [:runners, flow_id], &%{&1 | state: final_state, status: :done})

        broadcast(flow_id, state, {:done, final_state})
        {:noreply, state}

      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:from_flow, flow_id, {:flow_error, reason}}, state) do
    case Map.fetch(state.runners, flow_id) do
      {:ok, _} ->
        state = update_in(state, [:runners, flow_id], &%{&1 | status: :error})
        broadcast(flow_id, state, {:error, inspect(reason)})
        {:noreply, state}

      :error ->
        {:noreply, state}
    end
  end

  # Runner :DOWN → drop the record, notify subscribers.
  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Map.pop(state.monitors, ref) do
      {nil, _} ->
        {:noreply, state}

      {{:sub, _}, monitors} ->
        state = %{state | monitors: monitors}

        subs =
          Map.new(state.subs, fn {fid, pids} ->
            {fid, Enum.reject(pids, fn p -> not Process.alive?(p) end)}
          end)

        {:noreply, %{state | subs: subs}}

      {{:runner, flow_id}, monitors} ->
        state = %{state | monitors: monitors}

        case Map.get(state.runners, flow_id) do
          nil ->
            {:noreply, state}

          runner ->
            if Process.alive?(runner.forwarder), do: send(runner.forwarder, :stop)
            runners = Map.delete(state.runners, flow_id)
            broadcast(flow_id, state, {:terminated, %{reason: inspect(reason)}})
            {:noreply, %{state | runners: runners}}
        end
    end
  end

  # With trap_exit on, linked process exits arrive here instead of
  # killing us. A :normal {:EXIT, _, :normal} is harmless; anything
  # else we log but swallow.
  @impl true
  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  @impl true
  def handle_info({:EXIT, pid, reason}, state) do
    require Logger
    Logger.warning("FlowController: linked process #{inspect(pid)} exited: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # --- Helpers ----------------------------------------------------------

  defp terminate_existing(state, flow_id) do
    case Map.get(state.runners, flow_id) do
      nil ->
        state

      %{pid: pid} ->
        Flow.stop(pid)
        state
    end
  end

  defp snapshot_of(state, flow_id) do
    case Map.get(state.runners, flow_id) do
      nil -> %{status: "idle", state: nil, started_at: nil}
      r -> %{status: Atom.to_string(r.status), state: r.state, started_at: r.started_at}
    end
  end

  defp broadcast(flow_id, state, event) do
    envelope = {:flow_update, flow_id, envelope_for(event)}

    for sub <- Map.get(state.subs, flow_id, []), do: send(sub, envelope)
  end

  defp envelope_for({:started, payload}), do: %{kind: "started", payload: payload}
  defp envelope_for({:state, new_state}), do: %{kind: "state", payload: %{state: new_state}}
  defp envelope_for({:done, final_state}), do: %{kind: "done", payload: %{state: final_state}}
  defp envelope_for({:error, reason}), do: %{kind: "error", payload: %{reason: reason}}
  defp envelope_for({:terminated, payload}), do: %{kind: "terminated", payload: payload}

  # Per-flow tagger that re-emits runner notifications with the flow id.
  # Exits normally on `:stop` — because Erlang's selective receive
  # scans the mailbox in FIFO order, any `{:flow_state, _}` /
  # `{:flow_done, _}` messages already queued ahead of `:stop` are
  # forwarded first, guaranteeing no telemetry is lost on shutdown.
  defp forward_loop(controller, flow_id) do
    receive do
      :stop ->
        :ok

      msg ->
        send(controller, {:from_flow, flow_id, msg})
        forward_loop(controller, flow_id)
    end
  end
end
