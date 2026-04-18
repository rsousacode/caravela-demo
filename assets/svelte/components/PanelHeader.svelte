<script>
  let { panel, subtitle = "" } = $props();
</script>

<div class="px-8 py-6 border-b border-ink-700/60">
  <div class="flex items-baseline gap-3">
    <span class="text-{panel.accent} text-2xl leading-none">{panel.glyph}</span>
    <h1 class="text-xl font-semibold text-ink-50 tracking-tight">{panel.label}</h1>
    <span class="text-ink-500 text-sm">·</span>
    <span class="text-ink-400 text-sm">{panel.hint}</span>
  </div>
  {#if subtitle}
    <p class="text-ink-400 text-sm mt-2 max-w-3xl leading-relaxed">{subtitle}</p>
  {/if}
</div>
