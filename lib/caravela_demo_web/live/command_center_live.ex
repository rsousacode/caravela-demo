defmodule CaravelaDemoWeb.CommandCenterLive do
  @moduledoc """
  Root LiveView hosting the Caravela Command Center Svelte application.

  State is kept deliberately small here — the Svelte app owns UI state,
  and the server only pushes authoritative framework state (domain IR,
  flow states, generator output) back down.
  """

  use CaravelaDemoWeb, :live_view

  import LiveSvelte

  alias CaravelaDemoWeb.DomainSerializer

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

    {:ok, socket}
  end

  @impl true
  def handle_event("navigate", %{"panel" => panel}, socket) when panel in @panels do
    {:noreply, assign(socket, :active_panel, panel)}
  end

  def handle_event("navigate", _params, socket), do: {:noreply, socket}

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
          domain: @domain
        }
      }
      socket={@socket}
    />
    """
  end

  defp load_domain do
    ir = DomainSerializer.serialize(Caravela.domain!(@domain_module))
    source = read_source(@domain_source_path)
    Map.put(ir, :source, source)
  end

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
