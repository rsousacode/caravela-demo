<script>
  import DomainPanel from "./panels/DomainPanel.svelte";
  import GeneratorsPanel from "./panels/GeneratorsPanel.svelte";
  import FlowsPanel from "./panels/FlowsPanel.svelte";
  import PlaceholderPanel from "./panels/PlaceholderPanel.svelte";

  let { panel, live, domain, generators } = $props();
</script>

<div class="h-full w-full overflow-hidden">
  {#if panel.id === "domain"}
    <DomainPanel {panel} {live} {domain} />
  {:else if panel.id === "generators"}
    <GeneratorsPanel {panel} {live} {generators} />
  {:else if panel.id === "flows"}
    <FlowsPanel {panel} {live} />
  {:else}
    <PlaceholderPanel {panel} />
  {/if}
</div>
