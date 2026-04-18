defmodule CaravelaDemoWeb.CommandCenterLive do
  @moduledoc """
  Root LiveView hosting the Caravela Command Center Svelte application.

  State is kept deliberately small here — the Svelte app owns UI state,
  and the server only pushes authoritative framework state (domain IR,
  flow states, generator output) back down.
  """

  use CaravelaDemoWeb, :live_view

  import LiveSvelte

  alias CaravelaDemo.FlowController
  alias CaravelaDemo.Flows, as: FlowCatalog
  alias CaravelaDemoWeb.{
    DomainSerializer,
    FlowSerializer,
    FormPanel,
    GeneratorRunner,
    LiveRuntimePanel,
    VariantRunner
  }

  @panels ~w(domain generators flows forms runtime crud tenancy)
  @domain_module CaravelaDemo.Domains.Library
  @domain_source_path "lib/caravela_demo/domains/library.ex"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Command Center")
      |> assign(:active_panel, "domain")
      |> assign(:panels, @panels)
      |> assign(:build_info, build_info())
      |> assign(:domain, load_domain())
      |> assign(:generators, load_generators())
      |> assign(:flows, load_flows())
      |> assign(:form, FormPanel.initial())
      |> assign(:live_runtime, LiveRuntimePanel.initial())
      |> assign(:variants, VariantRunner.all())

    socket =
      if connected?(socket) do
        subscribe_to_flows()
        assign(socket, :flow_snapshot, current_flow_snapshot())
      else
        assign(socket, :flow_snapshot, %{})
      end

    {:ok, socket}
  end

  # --- Events ----------------------------------------------------------

  @impl true
  def handle_event("navigate", %{"panel" => panel}, socket) when panel in @panels do
    {:noreply, assign(socket, :active_panel, panel)}
  end

  def handle_event("navigate", _params, socket), do: {:noreply, socket}

  def handle_event("flow:start", %{"flow_id" => flow_id}, socket) do
    FlowController.start(flow_id)
    {:noreply, socket}
  end

  def handle_event("flow:stop", %{"flow_id" => flow_id}, socket) do
    FlowController.stop_flow(flow_id)
    {:noreply, socket}
  end

  def handle_event("flow:signal", %{"flow_id" => flow_id, "signal_id" => signal_id}, socket) do
    FlowController.signal(flow_id, signal_id)
    {:noreply, socket}
  end

  # --- Form events ----------------------------------------------------

  def handle_event("form:set_role", %{"role" => role}, socket) do
    form = FormPanel.set_role(socket.assigns.form, role)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("form:change", %{"field" => field, "value" => value}, socket) do
    form = FormPanel.change_field(socket.assigns.form, field, value)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("form:validate_async", %{"field" => field, "value" => value}, socket) do
    parent = self()
    assigns = socket.assigns.form

    Task.start(fn ->
      result = FormPanel.run_async_validator(field, value, assigns)
      send(parent, {:form_async_result, field, value, result})
    end)

    form = FormPanel.kickoff_async_validate(socket.assigns.form, field, value)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("form:save", _params, socket) do
    form = FormPanel.save(socket.assigns.form)
    socket = assign(socket, :form, form)

    socket =
      if form.saving do
        Process.send_after(self(), :form_save_done, 500)
        socket
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("form:reset", _params, socket) do
    {:noreply, assign(socket, :form, FormPanel.reset(socket.assigns.form))}
  end

  # --- Live runtime events -------------------------------------------

  def handle_event("live_runtime:run", %{"action_id" => action_id}, socket) do
    case LiveRuntimePanel.start_action(socket.assigns.live_runtime, action_id) do
      nil ->
        {:noreply, socket}

      {panel, 0} ->
        send(self(), {:live_runtime_step, action_id, 0})
        {:noreply, assign(socket, :live_runtime, panel)}
    end
  end

  def handle_event("live_runtime:stop", _params, socket) do
    {:noreply, assign(socket, :live_runtime, LiveRuntimePanel.stop(socket.assigns.live_runtime))}
  end

  def handle_event("live_runtime:reset", _params, socket) do
    {:noreply, assign(socket, :live_runtime, LiveRuntimePanel.reset(socket.assigns.live_runtime))}
  end

  # --- Flow notifications ---------------------------------------------

  @impl true
  def handle_info({:flow_update, flow_id, %{kind: kind, payload: payload}}, socket) do
    event = %{
      flow_id: flow_id,
      kind: kind,
      payload: serialize_payload(payload),
      at: System.system_time(:millisecond)
    }

    {:noreply, push_event(socket, "flow:update", event)}
  end

  def handle_info({:form_async_result, field, value, result}, socket) do
    form = FormPanel.apply_async_result(socket.assigns.form, field, value, result)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_info(:form_save_done, socket) do
    {:noreply, assign(socket, :form, FormPanel.save_done(socket.assigns.form))}
  end

  def handle_info({:live_runtime_step, action_id, idx}, socket) do
    panel = socket.assigns.live_runtime

    if panel.active_action == action_id do
      {panel, next} = LiveRuntimePanel.run_step(panel, idx)
      socket = assign(socket, :live_runtime, panel)

      case next do
        :done -> {:noreply, socket}
        ms -> Process.send_after(self(), {:live_runtime_step, action_id, idx + 1}, ms); {:noreply, socket}
      end
    else
      # Action was stopped or superseded.
      {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # --- Render ----------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <.svelte
      name="App"
      props={
        %{
          activePanel: @active_panel,
          panels: @panels,
          buildInfo: @build_info,
          domain: @domain,
          generators: @generators,
          flows: @flows,
          flowSnapshot: @flow_snapshot,
          form: @form,
          liveRuntime: @live_runtime,
          variants: @variants
        }
      }
      socket={@socket}
    />
    """
  end

  # --- Loaders ---------------------------------------------------------

  defp load_domain do
    ir = DomainSerializer.serialize(Caravela.domain!(@domain_module))
    source = read_source(@domain_source_path)
    Map.put(ir, :source, source)
  end

  defp load_generators do
    gens = GeneratorRunner.run_all(@domain_module)
    snapshots = CaravelaDemoWeb.GeneratorSnapshot.load_all()

    Enum.map(gens, fn g ->
      baseline = Map.get(snapshots, g.id, [])
      diff = CaravelaDemoWeb.GeneratorDiff.compare(baseline, g.files)
      baseline_map = Map.new(baseline, fn f -> {f.path, f.content} end)

      g
      |> Map.put(:diff, diff)
      |> Map.put(:baseline_map, baseline_map)
    end)
  end

  defp load_flows do
    Enum.map(FlowCatalog.catalog(), fn entry ->
      tree =
        FlowSerializer.serialize_tree(
          Module.concat([entry.module]),
          String.to_existing_atom(entry.flow_name)
        )

      Map.put(entry, :tree, tree)
    end)
  end

  defp current_flow_snapshot do
    FlowController.running()
    |> Map.new(fn {id, r} ->
      {id,
       %{
         status: r.status,
         state: FlowSerializer.serialize_state(r.state),
         started_at: r.started_at
       }}
    end)
  end

  defp subscribe_to_flows do
    for entry <- FlowCatalog.catalog(), do: FlowController.subscribe(entry.id)
  end

  defp serialize_payload(%{state: state} = payload) when is_map(state) do
    Map.put(payload, :state, FlowSerializer.serialize_state(state))
  end

  defp serialize_payload(payload), do: payload

  defp read_source(relative) do
    path = Application.app_dir(:caravela_demo, "..") |> Path.join(relative)

    case File.read(path) do
      {:ok, content} -> content
      _ -> File.read!(relative)
    end
  rescue
    _ -> "# source not found at #{relative}"
  end

  defp build_info do
    %{
      caravelaVersion: caravela_version(),
      elixir: System.version(),
      otp: System.otp_release(),
      env: to_string(Mix.env())
    }
  end

  defp caravela_version do
    case :application.get_key(:caravela, :vsn) do
      {:ok, vsn} -> to_string(vsn)
      _ -> "dev"
    end
  end
end
