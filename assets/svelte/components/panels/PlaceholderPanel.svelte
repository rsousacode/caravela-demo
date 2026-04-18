<script>
  import PanelHeader from "../PanelHeader.svelte";

  let { panel } = $props();
</script>

<div class="h-full flex flex-col">
  <PanelHeader {panel} subtitle="This panel is part of a later phase in the demo build." />

  <div class="flex-1 grid place-items-center p-10">
    <div
      class="max-w-md text-center space-y-4 border border-ink-700/80 rounded-2xl px-10 py-14 bg-ink-900/50"
    >
      <div class="text-5xl text-{panel.accent}">{panel.glyph}</div>
      <h2 class="text-ink-100 text-lg font-medium">Coming in a later phase</h2>
      <p class="text-ink-400 text-sm leading-relaxed">
        The shell is live — this panel is a placeholder while we finish the
        Domain, Generators, and Flows surfaces first.
      </p>
      <div
        class="inline-flex items-center gap-2 text-[11px] uppercase tracking-widest text-ink-500 border border-ink-700 rounded-full px-3 py-1"
      >
        <span class="h-1.5 w-1.5 rounded-full bg-sand animate-pulse"></span>
        scheduled
      </div>
    </div>
  </div>
</div>
