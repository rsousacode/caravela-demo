<script>
  let { entity, accent = "wave-400" } = $props();

  const typeColor = {
    string: "text-wave-400",
    text: "text-wave-400",
    integer: "text-sand",
    decimal: "text-sand",
    boolean: "text-reef",
    date: "text-sail",
    datetime: "text-sail",
    binary_id: "text-ember",
    uuid: "text-ember",
  };

  function colorFor(type) {
    return typeColor[type] ?? "text-ink-300";
  }
</script>

<div
  class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden hover:border-{accent}/50 transition-colors"
>
  <div class="px-4 py-3 border-b border-ink-700/60 flex items-center justify-between">
    <div class="flex items-center gap-2 min-w-0">
      <span class="h-2 w-2 rounded-full bg-{accent} shrink-0"></span>
      <span class="text-ink-50 font-semibold truncate">{entity.name}</span>
    </div>
    <span class="text-[11px] text-ink-500">{entity.field_count} fields</span>
  </div>

  <ul class="divide-y divide-ink-800/60">
    {#each entity.fields as field (field.name)}
      <li class="px-4 py-2 flex items-center justify-between gap-3 text-[13px]">
        <div class="flex items-center gap-2 min-w-0">
          <span class="text-ink-100 font-medium truncate">{field.name}</span>
          {#if field.required}
            <span class="text-[9px] uppercase tracking-wider text-ember font-semibold"
              >req</span
            >
          {/if}
        </div>
        <div class="flex items-center gap-2 text-right shrink-0">
          {#each field.constraints as c}
            <span
              class="text-[10px] text-ink-400 bg-ink-800/80 border border-ink-700 rounded px-1.5 py-[1px]"
              title="{c.key} = {c.value}"
            >
              {c.key}
            </span>
          {/each}
          <span class="{colorFor(field.type)} text-[12px]">:{field.type}</span>
        </div>
      </li>
    {/each}
  </ul>
</div>
