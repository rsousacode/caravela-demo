<script>
  import PanelHeader from "../PanelHeader.svelte";
  import UpdaterPipeline from "../runtime/UpdaterPipeline.svelte";
  import TraceLog from "../runtime/TraceLog.svelte";
  import FlowStateTree from "../flows/FlowStateTree.svelte";

  let { panel, liveRuntime, live } = $props();

  const actions = $derived(liveRuntime?.actions ?? []);
  const state = $derived(liveRuntime?.state ?? {});
  const trace = $derived(liveRuntime?.trace ?? []);
  const activeId = $derived(liveRuntime?.active_action ?? null);
  const stepIdx = $derived(liveRuntime?.step_index ?? null);
  const running = $derived(liveRuntime?.running ?? false);

  const activeAction = $derived(
    activeId ? actions.find((a) => a.id === activeId) : null,
  );

  let lastViewedId = $state(null);
  const viewedAction = $derived(
    activeAction ?? actions.find((a) => a.id === lastViewedId) ?? actions[0],
  );

  function run(id) {
    lastViewedId = id;
    live?.pushEvent("live_runtime:run", { action_id: id });
  }

  function stop() {
    live?.pushEvent("live_runtime:stop", {});
  }

  function reset() {
    live?.pushEvent("live_runtime:reset", {});
  }
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Caravela.Live.Domain declares state fields + named updaters; Caravela.Live.Updater composes them. Pick an action — the server applies each updater on a 300ms cadence, diffs state in the trace panel, and streams each step here over the LiveView socket."
  />

  <div class="flex-1 min-h-0 grid grid-cols-12 gap-0">
    <!-- Left: action catalog -->
    <aside class="col-span-3 border-r border-ink-700/60 bg-ink-900/40 flex flex-col min-h-0">
      <div
        class="px-4 py-3 border-b border-ink-700/60 text-xs uppercase tracking-widest text-ink-500 flex items-center justify-between"
      >
        <span>Actions · {actions.length}</span>
        <button
          type="button"
          onclick={reset}
          class="text-[11px] text-ink-400 hover:text-ink-200 normal-case tracking-normal"
          title="Clear state + trace"
        >
          reset state
        </button>
      </div>
      <nav class="flex-1 overflow-auto py-2 px-2 space-y-1.5">
        {#each actions as a (a.id)}
          {@const active = a.id === activeId}
          {@const viewed = a.id === (viewedAction?.id ?? null)}
          <button
            type="button"
            onclick={() => run(a.id)}
            class="w-full text-left p-3 rounded-lg border transition-all
                   {active
              ? `border-${a.accent} bg-ink-800/90 ring-1 ring-${a.accent}/50 shadow-lg`
              : viewed
                ? `border-${a.accent}/60 bg-ink-800/60`
                : 'border-ink-700/70 bg-ink-900/40 hover:border-ink-600'}"
          >
            <div class="flex items-center justify-between mb-1">
              <span
                class="text-[13px] font-medium {active || viewed
                  ? `text-${a.accent}`
                  : 'text-ink-100'}"
              >
                {a.label}
              </span>
              {#if active && running}
                <span class="text-[10px] uppercase tracking-widest text-reef">running</span>
              {:else}
                <span class="text-[10px] text-ink-500">▷</span>
              {/if}
            </div>
            <div class="text-[11px] text-ink-400 line-clamp-2 mb-2">{a.description}</div>
            <div class="flex flex-wrap gap-1">
              {#each a.pipeline as step}
                {#if step.type === "wait"}
                  <code
                    class="text-[10px] text-ink-500 border border-dashed border-ink-700 rounded px-1 py-[1px]"
                  >
                    {step.arg}
                  </code>
                {:else}
                  <code
                    class="text-[10px] text-ink-300 bg-ink-800/80 border border-ink-700 rounded px-1 py-[1px]"
                  >
                    {step.label}
                  </code>
                {/if}
              {/each}
            </div>
          </button>
        {/each}
      </nav>
    </aside>

    <!-- Center: pipeline + action details -->
    <section class="col-span-6 flex flex-col min-h-0 border-r border-ink-700/60">
      {#if viewedAction}
        <div class="px-6 py-4 border-b border-ink-700/60 flex items-start gap-3">
          <div class="flex-1 min-w-0">
            <h2 class="text-[15px] font-semibold text-{viewedAction.accent}">
              {viewedAction.label}
            </h2>
            <p class="text-[12px] text-ink-400 mt-1 max-w-2xl leading-relaxed">
              {viewedAction.description}
            </p>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            {#if running && activeId === viewedAction.id}
              <button
                onclick={stop}
                class="px-3 py-1.5 text-[12px] border border-coral/40 text-coral rounded-lg hover:bg-coral/10"
              >
                ■ stop
              </button>
            {:else}
              <button
                onclick={() => run(viewedAction.id)}
                class="px-3 py-1.5 text-[12px] border border-{viewedAction.accent}/50 text-{viewedAction.accent} rounded-lg hover:bg-{viewedAction.accent}/10"
              >
                ▷ run
              </button>
            {/if}
          </div>
        </div>

        <div class="flex-1 min-h-0 overflow-auto p-5 space-y-4">
          <UpdaterPipeline
            pipeline={viewedAction.pipeline}
            currentIndex={activeId === viewedAction.id ? stepIdx : null}
            accent={viewedAction.accent}
            running={running && activeId === viewedAction.id}
          />

          <div
            class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4 text-[12px] text-ink-400 leading-relaxed"
          >
            <div class="text-[11px] text-ink-500 uppercase tracking-widest mb-2">
              How composition works
            </div>
            <p>
              Each step resolves against <code class="text-ink-300">BookEditorDomain.__caravela_live_updater__/1</code>.
              The server walks steps on a 300ms cadence (waits override
              the cadence with their own duration), applies the updater
              to the current state, and pushes the new state + diff
              to this panel. Real LiveViews do the same, just without
              the artificial delay — it's the same <code class="text-ink-300">Caravela.Live.Updater.run/2,3</code>
              call underneath.
            </p>
          </div>
        </div>
      {:else}
        <div class="flex-1 grid place-items-center text-ink-500">
          select an action on the left
        </div>
      {/if}
    </section>

    <!-- Right: state + trace -->
    <aside class="col-span-3 flex flex-col min-h-0 p-4 gap-4">
      <div class="flex-1 min-h-0">
        <FlowStateTree {state} />
      </div>
      <div class="flex-1 min-h-0">
        <TraceLog {trace} />
      </div>
    </aside>
  </div>
</div>
