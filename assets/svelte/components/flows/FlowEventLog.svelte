<script>
  let { log = [] } = $props();

  const KIND_COLOR = {
    started: "text-reef",
    state: "text-ink-300",
    done: "text-wave-400",
    error: "text-coral",
    terminated: "text-ink-500",
  };

  function formatTime(ms) {
    const d = new Date(ms);
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}.${String(d.getMilliseconds()).padStart(3, "0")}`;
  }

  const reversed = $derived([...log].reverse());
</script>

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden flex flex-col min-h-0">
  <div
    class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between shrink-0"
  >
    <span class="text-xs text-ink-400 uppercase tracking-widest">Event log</span>
    <span class="text-[11px] text-ink-500">{log.length}</span>
  </div>
  <div class="overflow-auto text-[12px] font-mono flex-1">
    {#if reversed.length === 0}
      <div class="text-ink-500 italic p-3">no events yet</div>
    {:else}
      <ul class="divide-y divide-ink-800/60">
        {#each reversed as entry (entry.id)}
          <li class="px-3 py-1.5 flex items-start gap-3">
            <span class="text-ink-600 shrink-0 w-24">{formatTime(entry.at)}</span>
            <span class="shrink-0 w-16 {KIND_COLOR[entry.kind] ?? 'text-ink-400'}">{entry.kind}</span>
            <span class="flex-1 text-ink-300 break-all">{entry.summary}</span>
          </li>
        {/each}
      </ul>
    {/if}
  </div>
</div>
