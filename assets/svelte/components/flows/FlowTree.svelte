<script>
  let { tree, currentStep = null, status = "idle" } = $props();

  function typeColor(type) {
    switch (type) {
      case "wait_until":
        return "sail";
      case "debounce":
        return "reef";
      case "run":
        return "ember";
      case "parallel":
        return "wave-400";
      case "race":
        return "sand";
      case "repeat":
        return "ink-300";
      case "sequence":
        return "ink-500";
      default:
        return "ink-400";
    }
  }

  function isActive(node) {
    if (status === "done" || status === "error" || status === "stopped") return false;
    if (currentStep === "done") return false;
    return node.type === currentStep;
  }

  function opsSummary(opts) {
    if (!opts || Object.keys(opts).length === 0) return "";
    return Object.entries(opts)
      .map(([k, v]) => `${k}:${v}`)
      .join(" · ");
  }
</script>

{#snippet node(n, depth)}
  {@const active = isActive(n)}
  {@const color = typeColor(n.type)}
  <div class="pl-{depth * 4}" style="padding-left: {depth * 18}px">
    {#if n.type === "sequence" || n.type === "repeat"}
      <div class="flex items-center gap-2 py-1 text-[11px] uppercase tracking-widest text-{color}">
        <span class="h-2 w-2 rounded-full bg-{color}/30 border border-{color}"></span>
        {n.label}
      </div>
    {:else}
      <div
        class="flex items-center gap-2 px-2.5 py-1.5 rounded-md mb-0.5 text-[12px]
               {active
          ? `bg-${color}/10 border border-${color}/60 text-ink-50 shadow-lg animate-pulse`
          : 'text-ink-300 border border-transparent hover:bg-ink-800/40'}"
      >
        <span
          class="shrink-0 h-1.5 w-1.5 rounded-full {active
            ? `bg-${color} shadow-[0_0_8px_currentColor]`
            : `bg-${color}/30`}"
        ></span>
        <span class="font-mono">{n.label}</span>
        {#if opsSummary(n.opts)}
          <span class="ml-auto text-[10px] text-ink-500">{opsSummary(n.opts)}</span>
        {/if}
      </div>
    {/if}
    {#each n.children ?? [] as child (child.id)}
      {@render node(child, depth + 1)}
    {/each}
  </div>
{/snippet}

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden">
  <div
    class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between"
  >
    <span class="text-xs text-ink-400 uppercase tracking-widest">Step tree</span>
    <span class="text-[11px] text-ink-500">
      current step:
      <span class="text-ink-200">{currentStep ?? "–"}</span>
    </span>
  </div>
  <div class="p-3 overflow-auto">
    {@render node(tree, 0)}
  </div>
</div>
