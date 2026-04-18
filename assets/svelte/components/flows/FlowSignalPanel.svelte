<script>
  let { flow, status = "idle", onSignal = () => {}, accent = "wave-400" } = $props();

  const signals = $derived(flow?.signals ?? []);
  const running = $derived(status === "running");
</script>

<div
  class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden"
>
  <div
    class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between"
  >
    <span class="text-xs text-ink-400 uppercase tracking-widest">Signals</span>
    {#if !running}
      <span class="text-[11px] text-ink-500">start the flow to enable</span>
    {/if}
  </div>

  {#if signals.length === 0}
    <div class="p-4 text-[12px] text-ink-500 italic">
      This flow is autonomous — it completes without external input.
    </div>
  {:else}
    <div class="p-3 grid grid-cols-1 gap-2">
      {#each signals as sig (sig.id)}
        <button
          type="button"
          disabled={!running}
          onclick={() => onSignal(sig.id)}
          class="flex flex-col items-start text-left px-3.5 py-2 rounded-lg border transition-all
                 {running
            ? `border-ink-700 hover:border-${accent}/60 hover:bg-${accent}/10 active:scale-[0.98]`
            : 'border-ink-800 text-ink-600 cursor-not-allowed'}"
        >
          <span
            class="text-[13px] font-medium {running ? `text-${accent}` : 'text-ink-600'}"
          >
            {sig.label}
          </span>
          <span class="text-[11px] text-ink-500 mt-0.5">{sig.hint}</span>
        </button>
      {/each}
    </div>
  {/if}
</div>
