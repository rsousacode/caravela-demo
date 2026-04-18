<script>
  import DomainPanel from "./panels/DomainPanel.svelte";
  import GeneratorsPanel from "./panels/GeneratorsPanel.svelte";
  import FlowsPanel from "./panels/FlowsPanel.svelte";
  import FormsPanel from "./panels/FormsPanel.svelte";
  import LiveRuntimePanel from "./panels/LiveRuntimePanel.svelte";
  import TenancyPanel from "./panels/TenancyPanel.svelte";
  import CrudPanel from "./panels/CrudPanel.svelte";
  import PlaceholderPanel from "./panels/PlaceholderPanel.svelte";

  let {
    panel,
    live,
    domain,
    generators,
    flows,
    flowSnapshot,
    form,
    liveRuntime,
    variants,
    crud,
  } = $props();
</script>

<div class="h-full w-full overflow-hidden">
  {#if panel.id === "domain"}
    <DomainPanel {panel} {live} {domain} />
  {:else if panel.id === "generators"}
    <GeneratorsPanel {panel} {live} {generators} />
  {:else if panel.id === "flows"}
    <FlowsPanel {panel} {live} {flows} {flowSnapshot} />
  {:else if panel.id === "forms"}
    <FormsPanel {panel} {live} {form} />
  {:else if panel.id === "runtime"}
    <LiveRuntimePanel {panel} {live} {liveRuntime} />
  {:else if panel.id === "tenancy"}
    <TenancyPanel {panel} {variants} />
  {:else if panel.id === "crud"}
    <CrudPanel {panel} {crud} />
  {:else}
    <PlaceholderPanel {panel} />
  {/if}
</div>
