<script>
  import PanelHeader from "../PanelHeader.svelte";

  let { panel } = $props();

  const generators = [
    { task: "mix caravela.gen", outputs: ["Ecto schemas", "Migration", "Context", "JSON API"], count: 8 },
    { task: "mix caravela.gen.schema", outputs: ["Ecto schemas", "Migration"], count: 4 },
    { task: "mix caravela.gen.context", outputs: ["Phoenix context w/ hooks"], count: 1 },
    { task: "mix caravela.gen.api", outputs: ["JSON controllers", "Router snippet"], count: 4 },
    { task: "mix caravela.gen.graphql", outputs: ["Absinthe types", "Queries", "Mutations"], count: 3 },
    { task: "mix caravela.gen.live", outputs: ["LiveViews", "Svelte components", "TS types"], count: 10 },
  ];
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Every generator reads the same IR. Change a field in the domain, re-run, and Ecto, GraphQL, LiveView, and Svelte all shift together — with a safe CUSTOM marker that preserves your hand-written extensions."
  />

  <div class="flex-1 overflow-auto p-8">
    <div class="grid grid-cols-2 gap-4 max-w-5xl">
      {#each generators as gen}
        <div
          class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-5 space-y-3 hover:border-sail/40 transition-colors"
        >
          <div class="flex items-center justify-between">
            <code class="text-sail text-sm font-medium">{gen.task}</code>
            <span class="text-[11px] text-ink-500">{gen.count} files</span>
          </div>
          <div class="flex flex-wrap gap-1.5">
            {#each gen.outputs as out}
              <span
                class="text-[11px] text-ink-300 bg-ink-800/80 border border-ink-700 rounded-full px-2.5 py-0.5"
              >
                {out}
              </span>
            {/each}
          </div>
          <button
            class="text-[12px] text-ink-400 hover:text-wave-400 transition-colors"
            disabled
          >
            preview output → <span class="text-ink-600">Phase 3</span>
          </button>
        </div>
      {/each}
    </div>
  </div>
</div>
