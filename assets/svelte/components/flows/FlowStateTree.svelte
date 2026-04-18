<script>
  let { state } = $props();

  function typeOf(v) {
    if (v === null) return "null";
    if (Array.isArray(v)) return "array";
    if (typeof v === "object") return "object";
    return typeof v;
  }

  function color(type) {
    switch (type) {
      case "string":
        return "text-reef";
      case "number":
        return "text-sand";
      case "boolean":
        return "text-sail";
      case "null":
        return "text-ink-500";
      case "array":
        return "text-ember";
      case "object":
        return "text-ink-300";
      default:
        return "text-ink-300";
    }
  }

  function preview(v) {
    const t = typeOf(v);
    if (t === "null") return "null";
    if (t === "string") return `"${v}"`;
    if (t === "boolean" || t === "number") return String(v);
    if (t === "array") return `[${v.length}]`;
    if (t === "object") return `{${Object.keys(v).length}}`;
    return String(v);
  }
</script>

{#snippet row(key, value, depth)}
  {@const t = typeOf(value)}
  <div class="flex items-start gap-2 text-[12px] leading-5 py-0.5">
    <span class="text-ink-600 select-none font-mono" style="padding-left: {depth * 16}px"></span>
    <span class="text-ink-400 font-mono">{key}:</span>
    {#if t === "object"}
      <div class="flex-1 min-w-0">
        <span class="text-ink-500">{`{`}</span>
        <div>
          {#each Object.entries(value) as [k, v]}
            {@render row(k, v, depth + 1)}
          {/each}
        </div>
        <span class="text-ink-500">{`}`}</span>
      </div>
    {:else if t === "array"}
      <div class="flex-1 min-w-0">
        <span class="text-ink-500">[</span>
        <div>
          {#each value as v, i}
            {@render row(String(i), v, depth + 1)}
          {/each}
        </div>
        <span class="text-ink-500">]</span>
      </div>
    {:else}
      <span class="{color(t)} font-mono break-all">{preview(value)}</span>
    {/if}
  </div>
{/snippet}

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden flex flex-col min-h-0">
  <div
    class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between shrink-0"
  >
    <span class="text-xs text-ink-400 uppercase tracking-widest">State</span>
    {#if state}
      <span class="text-[11px] text-ink-500">
        {Object.keys(state).length} keys
      </span>
    {/if}
  </div>
  <div class="p-3 overflow-auto flex-1 font-mono">
    {#if !state}
      <div class="text-ink-500 text-[12px] italic p-2">flow not running</div>
    {:else}
      {#each Object.entries(state) as [k, v]}
        {@render row(k, v, 0)}
      {/each}
    {/if}
  </div>
</div>
