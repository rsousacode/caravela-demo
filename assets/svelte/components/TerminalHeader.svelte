<script>
  let { panel, buildInfo } = $props();

  const commands = {
    domain: "iex> Caravela.domain!(CaravelaDemo.Domains.Library)",
    generators: "$ mix caravela.gen CaravelaDemo.Domains.Library --dry-run",
    flows: "iex> Caravela.Flow.start(DebounceFlow, :tick, notify: self())",
    forms: "iex> BookFormDomain.__caravela_form_visibility__(assigns)",
    runtime: "iex> BookEditorDomain.__caravela_live_state__()",
    crud: "$ mix caravela.gen.live CaravelaDemo.Domains.Library",
    tenancy: "$ mix caravela.gen CaravelaDemo.Domains.Library --tenant acme",
  };

  const cmd = $derived(commands[panel.id] ?? "iex>");
</script>

<header
  class="flex items-center gap-4 px-5 py-3 border-b border-ink-700/80 bg-ink-900/60 backdrop-blur"
>
  <div class="flex items-center gap-2">
    <span class="h-3 w-3 rounded-full bg-coral/80"></span>
    <span class="h-3 w-3 rounded-full bg-sand/80"></span>
    <span class="h-3 w-3 rounded-full bg-reef/80"></span>
  </div>

  <div class="flex-1 min-w-0 flex items-center gap-2 text-[13px]">
    <span class="text-ink-500">~/caravela_demo</span>
    <span class="text-ink-600">›</span>
    <span class="text-{panel.accent} font-medium">{panel.label.toLowerCase()}</span>
    <span class="text-ink-600">·</span>
    <span class="text-ink-300 truncate font-mono">{cmd}</span>
    <span class="inline-block w-2 h-4 bg-wave-400 animate-pulse ml-1"></span>
  </div>

  <div class="flex items-center gap-3 text-[11px] text-ink-500">
    <span class="flex items-center gap-1.5">
      <span class="h-2 w-2 rounded-full bg-reef animate-pulse"></span>
      connected
    </span>
    <span class="text-ink-700">|</span>
    <span>caravela {buildInfo.caravelaVersion}</span>
  </div>
</header>
