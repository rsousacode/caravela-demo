<script>
  import Sidebar from "./components/Sidebar.svelte";
  import TerminalHeader from "./components/TerminalHeader.svelte";
  import PanelRouter from "./components/PanelRouter.svelte";
  import { PANEL_BY_ID } from "$lib/panels.js";

  let {
    activePanel = "domain",
    buildInfo = {},
    domain = undefined,
    generators = [],
    flows = [],
    flowSnapshot = {},
    form = undefined,
    liveRuntime = undefined,
    variants = [],
    live = undefined,
  } = $props();

  const current = $derived(PANEL_BY_ID[activePanel] ?? PANEL_BY_ID.domain);

  function navigate(panelId) {
    if (panelId === activePanel) return;
    live?.pushEvent("navigate", { panel: panelId });
  }
</script>

<div class="flex h-screen w-screen panel-bg overflow-hidden">
  <Sidebar {activePanel} onNavigate={navigate} {buildInfo} />

  <div class="flex flex-col flex-1 min-w-0">
    <TerminalHeader panel={current} {buildInfo} />

    <main class="flex-1 min-h-0 overflow-hidden grid-fade">
      <PanelRouter
        panel={current}
        {live}
        {domain}
        {generators}
        {flows}
        {flowSnapshot}
        {form}
        {liveRuntime}
        {variants}
      />
    </main>
  </div>
</div>
