<script>
  import { onMount } from "svelte";
  import PanelHeader from "../PanelHeader.svelte";
  import FlowTree from "../flows/FlowTree.svelte";
  import FlowStateTree from "../flows/FlowStateTree.svelte";
  import FlowEventLog from "../flows/FlowEventLog.svelte";
  import FlowSignalPanel from "../flows/FlowSignalPanel.svelte";
  import { createFlowStore } from "$lib/flow_store.js";

  let { panel, flows = [], flowSnapshot = {}, live = undefined } = $props();

  const store = createFlowStore(flowSnapshot);
  let selectedId = $state(flows[0]?.id ?? "debounce");

  const selected = $derived(flows.find((f) => f.id === selectedId) ?? flows[0]);
  const record = $derived(store.map.get(selectedId) ?? store.get(selectedId));

  const status = $derived(record?.status ?? "idle");
  const currentStep = $derived(record?.state?.__step ?? null);
  const isRunning = $derived(status === "running");

  const STATUS_STYLE = {
    idle: { text: "idle", class: "text-ink-500 border-ink-700" },
    running: { text: "running", class: "text-reef border-reef/40" },
    done: { text: "done", class: "text-wave-400 border-wave-400/40" },
    error: { text: "error", class: "text-coral border-coral/40" },
    stopped: { text: "stopped", class: "text-ink-500 border-ink-700" },
  };

  onMount(() => {
    if (!live) return;

    const handler = (payload) => {
      store.apply(payload);
    };

    const off = live.handleEvent("flow:update", handler);
    return () => (typeof off === "function" ? off() : undefined);
  });

  function pushEv(name, data) {
    live?.pushEvent(name, data);
  }

  function start() {
    if (!selected) return;
    pushEv("flow:start", { flow_id: selected.id });
  }

  function stop() {
    if (!selected) return;
    pushEv("flow:stop", { flow_id: selected.id });
  }

  function signal(signalId) {
    if (!selected) return;
    pushEv("flow:signal", { flow_id: selected.id, signal_id: signalId });
  }

  function statusFor(id) {
    return store.map.get(id)?.status ?? store.get(id).status ?? "idle";
  }
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Flows are composable async state machines built on GenServer. Start one, send it signals, watch state tick in real time. Every step update streams over the LiveView socket — no polling."
  />

  <div class="flex-1 min-h-0 grid grid-cols-12 gap-0">
    <aside
      class="col-span-3 border-r border-ink-700/60 bg-ink-900/40 flex flex-col min-h-0"
    >
      <div
        class="px-4 py-3 border-b border-ink-700/60 text-xs uppercase tracking-widest text-ink-500"
      >
        Catalog · {flows.length}
      </div>
      <nav class="flex-1 overflow-auto py-2 px-2 space-y-1.5">
        {#each flows as f (f.id)}
          {@const st = statusFor(f.id)}
          {@const style = STATUS_STYLE[st] ?? STATUS_STYLE.idle}
          {@const active = f.id === selectedId}
          <button
            type="button"
            onclick={() => (selectedId = f.id)}
            class="w-full text-left p-3 rounded-lg border transition-all
                   {active
              ? `border-${f.accent}/60 bg-ink-800/80 ring-1 ring-${f.accent}/30`
              : 'border-ink-700/70 hover:border-ink-600 bg-ink-900/40'}"
          >
            <div class="flex items-center justify-between mb-1">
              <span
                class="text-[13px] font-medium {active
                  ? `text-${f.accent}`
                  : 'text-ink-100'}"
              >
                {f.title}
              </span>
              <span
                class="text-[10px] uppercase tracking-widest border rounded-full px-1.5 py-px {style.class}"
              >
                {style.text}
              </span>
            </div>
            <div class="text-[11px] text-ink-400 line-clamp-2 mb-2">
              {f.description}
            </div>
            <div class="flex flex-wrap gap-1">
              {#each f.primitives as p}
                <code
                  class="text-[10px] text-ink-400 bg-ink-800/80 border border-ink-700 rounded px-1 py-px"
                >
                  {p}
                </code>
              {/each}
            </div>
          </button>
        {/each}
      </nav>
    </aside>

    <section class="col-span-6 flex flex-col min-h-0 border-r border-ink-700/60">
      {#if selected}
        <div class="px-6 py-4 border-b border-ink-700/60 flex items-center gap-3">
          <div class="flex-1 min-w-0">
            <div class="flex items-baseline gap-3">
              <h2 class="text-[15px] font-semibold text-{selected.accent}">
                {selected.title}
              </h2>
              <code class="text-[11px] text-ink-500 truncate">
                {selected.module} · {selected.flow_name}
              </code>
            </div>
            <p class="text-[12px] text-ink-400 mt-1">{selected.description}</p>
          </div>
          <div class="flex items-center gap-2">
            {#if isRunning}
              <button
                onclick={stop}
                class="px-3 py-1.5 text-[12px] border border-coral/40 text-coral rounded-lg hover:bg-coral/10"
              >
                ■ stop
              </button>
            {:else}
              <button
                onclick={start}
                class="px-3 py-1.5 text-[12px] border border-{selected.accent}/50 text-{selected.accent} rounded-lg hover:bg-{selected.accent}/10"
              >
                ▷ start
              </button>
            {/if}
          </div>
        </div>

        <div class="flex-1 min-h-0 overflow-auto p-5 space-y-4">
          <FlowTree tree={selected.tree} {currentStep} {status} />
          <FlowSignalPanel
            flow={selected}
            {status}
            accent={selected.accent}
            onSignal={signal}
          />
        </div>
      {:else}
        <div class="flex-1 grid place-items-center text-ink-500">no flow selected</div>
      {/if}
    </section>

    <aside class="col-span-3 flex flex-col min-h-0 p-4 gap-4">
      <div class="flex-1 min-h-0">
        <FlowStateTree state={record?.state} />
      </div>
      <div class="flex-1 min-h-0">
        <FlowEventLog log={record?.log ?? []} />
      </div>
    </aside>
  </div>
</div>
