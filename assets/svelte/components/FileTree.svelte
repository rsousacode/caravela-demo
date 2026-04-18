<script>
  let { files = [], statuses = {}, selected = null, onSelect = () => {} } = $props();

  const STATUS_GLYPH = {
    added: { char: "+", class: "text-reef" },
    removed: { char: "-", class: "text-coral" },
    changed: { char: "~", class: "text-ember" },
    unchanged: { char: "·", class: "text-ink-600" },
  };

  const LANG_COLOR = {
    elixir: "text-sail",
    svelte: "text-ember",
    typescript: "text-wave-400",
    javascript: "text-sand",
    json: "text-reef",
  };

  const groups = $derived.by(() => {
    const by = new Map();
    for (const f of files) {
      const dir = f.path.split("/").slice(0, -1).join("/") || "(root)";
      if (!by.has(dir)) by.set(dir, []);
      by.get(dir).push(f);
    }
    return Array.from(by.entries()).map(([dir, items]) => ({ dir, items }));
  });

  function fileName(path) {
    return path.split("/").pop();
  }

  function statusFor(path) {
    return statuses[path] ?? "unchanged";
  }
</script>

<div class="h-full overflow-auto text-[12px] py-2">
  {#each groups as group (group.dir)}
    <div class="mb-1">
      <div
        class="px-4 py-1 text-[10px] uppercase tracking-widest text-ink-500 sticky top-0 bg-ink-900/90 backdrop-blur"
      >
        {group.dir}
      </div>
      <ul>
        {#each group.items as file (file.path)}
          {@const status = statusFor(file.path)}
          {@const glyph = STATUS_GLYPH[status]}
          {@const active = selected?.path === file.path}
          <li>
            <button
              type="button"
              onclick={() => onSelect(file)}
              class="w-full flex items-center gap-2 px-4 py-1.5 text-left hover:bg-ink-800/60 transition-colors
                     {active ? 'bg-ink-800 ring-1 ring-inset ring-wave-500/40' : ''}"
            >
              <span class="{glyph.class} w-3 text-center font-bold shrink-0">{glyph.char}</span>
              <span class="flex-1 min-w-0 truncate {active ? 'text-ink-50' : 'text-ink-200'}">
                {fileName(file.path)}
              </span>
              <span
                class="shrink-0 text-[10px] {LANG_COLOR[file.language] ?? 'text-ink-500'}"
              >
                {file.language}
              </span>
            </button>
          </li>
        {/each}
      </ul>
    </div>
  {/each}
</div>
