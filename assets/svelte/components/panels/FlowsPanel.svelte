<script>
  import PanelHeader from "../PanelHeader.svelte";

  let { panel } = $props();

  const flows = [
    { name: "DebounceFlow", desc: "Coalesce burst signals into one run after 500ms of silence", primitives: ["wait_until", "debounce", "run"], color: "reef" },
    { name: "RetryFlow", desc: "Flaky HTTP call with exponential backoff and max retries", primitives: ["run", "retry", "backoff"], color: "ember" },
    { name: "ParallelFlow", desc: "Three independent branches run concurrently; wait for all", primitives: ["parallel", "run"], color: "sail" },
    { name: "RaceFlow", desc: "Three branches; first to complete wins, others are cancelled", primitives: ["race", "run"], color: "sand" },
    { name: "BookSyncFlow", desc: "Canonical pattern: wait for dirty → debounce → sync → loop", primitives: ["wait_until", "debounce", "run", "repeat"], color: "wave-400" },
  ];
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Flows are composable async state machines built on GenServer. Start one, send it signals, watch its state tick in real time. The showpiece panel — interactive simulation lands in Phase 4."
  />

  <div class="flex-1 overflow-auto p-8 grid grid-cols-12 gap-6">
    <section class="col-span-8 space-y-3">
      <h2 class="text-xs uppercase tracking-widest text-ink-500 mb-3">Flow catalog</h2>
      {#each flows as flow}
        <div
          class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-5 hover:border-{flow.color}/50 transition-colors group"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="h-2 w-2 rounded-full bg-{flow.color}"></span>
                <h3 class="text-ink-50 font-medium">{flow.name}</h3>
              </div>
              <p class="text-sm text-ink-400 mt-1.5 leading-relaxed">{flow.desc}</p>
              <div class="flex flex-wrap gap-1.5 mt-3">
                {#each flow.primitives as p}
                  <code
                    class="text-[11px] text-ink-300 bg-ink-800/80 border border-ink-700 rounded px-1.5 py-0.5"
                    >{p}</code
                  >
                {/each}
              </div>
            </div>
            <button
              disabled
              class="shrink-0 text-[12px] text-ink-500 border border-ink-700 rounded-lg px-3 py-1.5"
            >
              start ▷
            </button>
          </div>
        </div>
      {/each}
    </section>

    <section class="col-span-4 space-y-3">
      <h2 class="text-xs uppercase tracking-widest text-ink-500 mb-3">Live state</h2>
      <div
        class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-5 h-64 grid place-items-center"
      >
        <div class="text-center space-y-2">
          <div class="text-4xl text-ink-700">≋</div>
          <div class="text-ink-400 text-sm">No flow running</div>
          <div class="text-ink-600 text-[11px]">Phase 4 wires this panel to Caravela.Flow</div>
        </div>
      </div>
      <div class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-5 space-y-2">
        <div class="text-xs uppercase tracking-widest text-ink-500">Event log</div>
        <div class="text-ink-600 text-[12px] font-mono">waiting for first signal…</div>
      </div>
    </section>
  </div>
</div>
