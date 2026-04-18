<script>
  let { pipeline = [], currentIndex = null, accent = "wave-400", running = false } = $props();

  function stepClass(step, idx) {
    const active = running && idx === currentIndex;
    const past = currentIndex != null && idx < currentIndex;

    if (step.type === "wait") {
      return active
        ? `border-${accent}/60 bg-${accent}/10 text-${accent}`
        : past
          ? "border-ink-700 text-ink-500"
          : "border-ink-800 text-ink-600";
    }

    return active
      ? `border-${accent} bg-${accent}/15 text-ink-50 shadow-[0_0_12px_currentColor] animate-pulse`
      : past
        ? "border-ink-600 bg-ink-800/60 text-ink-200"
        : "border-ink-700 bg-ink-900/60 text-ink-400";
  }
</script>

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden">
  <div
    class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between"
  >
    <span class="text-xs text-ink-400 uppercase tracking-widest">Updater pipeline</span>
    <span class="text-[11px] text-ink-500">
      {pipeline.length} step{pipeline.length === 1 ? "" : "s"}
    </span>
  </div>
  <div class="p-5 overflow-auto">
    <div class="flex items-center gap-2 flex-wrap">
      {#each pipeline as step, i (i)}
        {#if i > 0}
          <span class="text-ink-600 select-none">~&gt;</span>
        {/if}

        {#if step.type === "wait"}
          <div
            class="flex flex-col items-center text-[11px] px-3 py-2 rounded-lg border-2 border-dashed min-w-24 {stepClass(step, i)}"
          >
            <span class="font-mono">{step.arg}</span>
            <span class="text-[10px] uppercase tracking-wider opacity-60 mt-0.5">wait</span>
          </div>
        {:else}
          <div
            class="flex flex-col items-start text-[12px] px-3 py-2 rounded-lg border transition-all {stepClass(step, i)}"
          >
            <span class="font-mono font-semibold">{step.label}</span>
            {#if step.arg}
              <span class="font-mono text-[10px] opacity-70 mt-0.5">{step.arg}</span>
            {/if}
          </div>
        {/if}
      {/each}
    </div>
  </div>
</div>
