<script>
  import { PANELS } from "$lib/panels.js";

  let { activePanel, onNavigate, buildInfo } = $props();
</script>

<aside
  class="w-64 shrink-0 border-r border-ink-700/80 bg-ink-900/80 backdrop-blur flex flex-col"
>
  <div class="px-5 py-5 border-b border-ink-700/60">
    <div class="flex items-center gap-3">
      <div
        class="h-9 w-9 rounded-lg bg-gradient-to-br from-wave-500 to-sail grid place-items-center text-ink-900 font-bold text-lg shadow-lg glow-wave"
      >
        ⚓
      </div>
      <div class="leading-tight">
        <div class="text-ink-50 font-semibold tracking-tight text-sm">
          Caravela
        </div>
        <div class="text-ink-400 text-[11px] uppercase tracking-wider">
          Command Center
        </div>
      </div>
    </div>
  </div>

  <nav class="flex-1 overflow-y-auto py-3 px-3 space-y-1">
    {#each PANELS as panel (panel.id)}
      {@const active = panel.id === activePanel}
      <button
        type="button"
        onclick={() => onNavigate(panel.id)}
        class="group w-full flex items-start gap-3 px-3 py-2.5 rounded-lg text-left transition-all duration-150
               {active
          ? 'bg-ink-800 ring-1 ring-wave-500/40 shadow-inner'
          : 'hover:bg-ink-800/60'}"
      >
        <span
          class="text-lg leading-none mt-0.5 {active
            ? 'text-wave-400'
            : 'text-ink-400 group-hover:text-ink-200'}"
        >
          {panel.glyph}
        </span>
        <span class="flex-1 min-w-0">
          <span class="flex items-center gap-2">
            <span
              class="text-sm font-medium {active
                ? 'text-ink-50'
                : 'text-ink-200'}"
            >
              {panel.label}
            </span>
            {#if panel.status === "soon"}
              <span
                class="text-[9px] uppercase tracking-widest text-ink-500 border border-ink-600 rounded px-1 py-[1px]"
                >soon</span
              >
            {/if}
          </span>
          <span class="block text-[11px] text-ink-400 truncate mt-0.5">
            {panel.hint}
          </span>
        </span>
      </button>
    {/each}
  </nav>

  <footer class="px-5 py-4 border-t border-ink-700/60 text-[11px] text-ink-500 space-y-1">
    <div class="flex justify-between">
      <span>caravela</span>
      <span class="text-ink-300 font-semibold">v{buildInfo.caravelaVersion}</span>
    </div>
    <div class="flex justify-between">
      <span>elixir</span>
      <span class="text-ink-400">{buildInfo.elixir}</span>
    </div>
    <div class="flex justify-between">
      <span>otp</span>
      <span class="text-ink-400">{buildInfo.otp}</span>
    </div>
    <div class="flex justify-between">
      <span>env</span>
      <span class="text-reef">{buildInfo.env}</span>
    </div>
  </footer>
</aside>
