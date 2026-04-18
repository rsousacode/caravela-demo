<script>
  import PanelHeader from "../PanelHeader.svelte";
  import CodeBlock from "../CodeBlock.svelte";
  import DiffView from "../DiffView.svelte";
  import FileTree from "../FileTree.svelte";

  let { panel, generators = [] } = $props();

  const ACCENTS = {
    persistence: "wave-400",
    api: "sail",
    ui: "ember",
    meta: "sand",
  };

  let selectedGenId = $state("schema");
  let selectedFilePath = $state(null);
  let view = $state("current"); // "current" | "diff"

  const selectedGen = $derived(
    generators.find((g) => g.id === selectedGenId) ?? generators[0],
  );

  const selectedFile = $derived.by(() => {
    if (!selectedGen) return null;
    if (selectedFilePath) {
      const found = selectedGen.files.find((f) => f.path === selectedFilePath);
      if (found) return found;
    }
    return selectedGen.files[0] ?? null;
  });

  const hasBaseline = $derived(selectedGen?.diff?.has_baseline ?? false);

  function pickGen(id) {
    selectedGenId = id;
    selectedFilePath = null;
    view = "current";
  }

  function pickFile(file) {
    selectedFilePath = file.path;
  }
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Every generator reads the same compiled IR. The files below are live output — regenerate the snapshot with mix caravela_demo.snapshot and the diff viewer lights up when anything the templates emit changes."
  />

  <div class="px-6 pt-4 pb-3 border-b border-ink-800/60 flex gap-3 overflow-x-auto shrink-0">
    {#each generators as g (g.id)}
      {@const active = g.id === selectedGenId}
      {@const accent = ACCENTS[g.category] ?? "wave-400"}
      {@const gdiff = g.diff ?? { has_baseline: false, added: 0, removed: 0, changed: 0 }}
      {@const dirty = gdiff.has_baseline && gdiff.added + gdiff.removed + gdiff.changed > 0}
      <button
        type="button"
        onclick={() => pickGen(g.id)}
        class="shrink-0 min-w-60 text-left p-3.5 rounded-xl border transition-all
               {active
          ? `border-${accent}/60 bg-ink-800/80 ring-1 ring-${accent}/30 shadow-lg`
          : 'border-ink-700/70 bg-ink-900/40 hover:border-ink-600'}"
      >
        <div class="flex items-center justify-between mb-1">
          <code class="text-[12px] {active ? `text-${accent}` : 'text-ink-300'} font-semibold">
            {g.task}
          </code>
          <span
            class="text-[9px] uppercase tracking-widest rounded-full px-2 py-[1px]
                   {dirty ? 'bg-ember/10 text-ember border border-ember/30' : 'bg-ink-800 text-ink-500 border border-ink-700'}"
          >
            {dirty ? "modified" : gdiff.has_baseline ? "clean" : "no baseline"}
          </span>
        </div>
        <div class="text-[11px] text-ink-400 line-clamp-2">{g.description}</div>
        <div class="mt-2 flex items-center gap-3 text-[11px]">
          <span class="text-ink-500">{g.file_count} files</span>
          {#if gdiff.has_baseline && (gdiff.added || gdiff.changed || gdiff.removed)}
            <span class="text-ink-700">·</span>
            {#if gdiff.added}<span class="text-reef">+{gdiff.added}</span>{/if}
            {#if gdiff.changed}<span class="text-ember">~{gdiff.changed}</span>{/if}
            {#if gdiff.removed}<span class="text-coral">−{gdiff.removed}</span>{/if}
          {/if}
        </div>
      </button>
    {/each}
  </div>

  {#if selectedGen}
    <div class="flex-1 min-h-0 grid grid-cols-12">
      <aside class="col-span-4 border-r border-ink-700/60 bg-ink-900/40 flex flex-col min-h-0">
        <div class="px-4 py-3 border-b border-ink-700/60 flex items-center justify-between">
          <code class="text-[12px] text-ink-300">{selectedGen.task}</code>
          <span class="text-[11px] text-ink-500">{selectedGen.files.length} files</span>
        </div>
        <FileTree
          files={selectedGen.files}
          statuses={selectedGen.diff?.files ?? {}}
          selected={selectedFile}
          onSelect={pickFile}
        />
      </aside>

      <section class="col-span-8 flex flex-col min-h-0">
        {#if selectedFile}
          <div
            class="px-5 py-3 border-b border-ink-700/60 flex items-center gap-3 shrink-0"
          >
            <span class="text-[12px] text-ink-300 font-mono truncate flex-1">
              {selectedFile.path}
            </span>
            <span class="text-[11px] text-ink-500">
              {selectedFile.bytes} B · {selectedFile.language}
            </span>
            {#if hasBaseline}
              <div class="flex rounded-lg overflow-hidden border border-ink-700">
                <button
                  onclick={() => (view = "current")}
                  class="px-3 py-1 text-[11px] transition-colors
                         {view === 'current'
                    ? 'bg-ink-700 text-ink-50'
                    : 'text-ink-400 hover:text-ink-200'}"
                >
                  current
                </button>
                <button
                  onclick={() => (view = "diff")}
                  class="px-3 py-1 text-[11px] transition-colors
                         {view === 'diff'
                    ? 'bg-ink-700 text-ink-50'
                    : 'text-ink-400 hover:text-ink-200'}"
                >
                  vs baseline
                </button>
              </div>
            {/if}
          </div>

          {#if view === "diff" && hasBaseline}
            {@const status = selectedGen.diff.files[selectedFile.path] ?? "unchanged"}
            {@const base = selectedGen.baseline_map?.[selectedFile.path] ?? ""}
            <div class="text-[11px] px-5 py-1.5 text-ink-500 shrink-0 border-b border-ink-800/60">
              status: <span class="text-ink-200">{status}</span>
            </div>
            <DiffView baseline={base} current={selectedFile.content} />
          {:else}
            <div class="flex-1 min-h-0 p-5 flex">
              <div class="flex-1 min-h-0 flex">
                <CodeBlock
                  code={selectedFile.content}
                  lang={selectedFile.language}
                  filename=""
                />
              </div>
            </div>
          {/if}
        {:else}
          <div class="flex-1 grid place-items-center text-ink-500 text-sm">
            Select a file to view its contents.
          </div>
        {/if}
      </section>
    </div>
  {:else}
    <div class="flex-1 grid place-items-center text-ink-500">No generators loaded.</div>
  {/if}
</div>
