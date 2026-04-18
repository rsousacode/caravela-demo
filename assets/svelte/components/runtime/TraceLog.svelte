<script>
  let { trace = [] } = $props();

  const KIND_COLOR = {
    updater: "text-ember",
    wait: "text-ink-500",
    action: "text-wave-400",
    error: "text-coral",
  };

  function formatTime(ms) {
    const d = new Date(ms);
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}.${String(d.getMilliseconds()).padStart(3, "0")}`;
  }

  function previewVal(v) {
    if (v === null || v === undefined) return "null";
    if (typeof v === "string") return JSON.stringify(v);
    if (typeof v === "boolean" || typeof v === "number") return String(v);
    return String(v);
  }
</script>

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden flex flex-col min-h-0">
  <div
    class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between shrink-0"
  >
    <span class="text-xs text-ink-400 uppercase tracking-widest">Trace</span>
    <span class="text-[11px] text-ink-500">{trace.length}</span>
  </div>
  <div class="overflow-auto flex-1 text-[11.5px] font-mono">
    {#if trace.length === 0}
      <div class="p-4 text-ink-500 italic">no events yet — pick an action</div>
    {:else}
      <ul class="divide-y divide-ink-800/60">
        {#each trace as entry, idx (entry.at + "-" + idx)}
          <li class="px-3 py-2">
            <div class="flex items-baseline gap-2.5">
              <span class="text-ink-600 shrink-0">{formatTime(entry.at)}</span>
              <span
                class="shrink-0 {KIND_COLOR[entry.kind] ?? 'text-ink-300'}"
              >
                {entry.label}
              </span>
              {#if entry.detail}
                <span class="text-ink-400 font-normal">{entry.detail}</span>
              {/if}
            </div>
            {#if entry.diff && Object.keys(entry.diff).length > 0}
              <div class="ml-[92px] mt-1 space-y-0.5 text-[11px]">
                {#each Object.entries(entry.diff) as [key, change]}
                  <div class="flex items-baseline gap-2">
                    <span class="text-ink-500 w-32 shrink-0 truncate">{key}</span>
                    <span class="text-coral/80">{previewVal(change.from)}</span>
                    <span class="text-ink-600">→</span>
                    <span class="text-reef">{previewVal(change.to)}</span>
                  </div>
                {/each}
              </div>
            {/if}
          </li>
        {/each}
      </ul>
    {/if}
  </div>
</div>
