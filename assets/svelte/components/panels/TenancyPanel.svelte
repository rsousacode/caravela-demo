<script>
  import PanelHeader from "../PanelHeader.svelte";
  import CodeBlock from "../CodeBlock.svelte";
  import FileTree from "../FileTree.svelte";

  let { panel, variants = [] } = $props();

  let selectedVariantId = $state("baseline");
  let selectedFilePath = $state(null);

  const selected = $derived(
    variants.find((v) => v.id === selectedVariantId) ?? variants[0],
  );

  const selectedFile = $derived.by(() => {
    if (!selected) return null;
    if (selectedFilePath) {
      const f = selected.files.find((x) => x.path === selectedFilePath);
      if (f) return f;
    }
    // Default to the books schema if we can find it — most visually
    // instructive starting file.
    const books =
      selected.files.find((x) => /\/books?\.ex$/.test(x.path)) ??
      selected.files[0];
    return books ?? null;
  });

  function selectVariant(id) {
    selectedVariantId = id;
    selectedFilePath = null;
  }

  function selectFile(f) {
    selectedFilePath = f.path;
  }

  // Matrix of stats across variants for a quick visual comparison.
  const statsMatrix = $derived(
    variants.map((v) => ({
      id: v.id,
      title: v.title,
      accent: v.accent,
      multi_tenant: v.ir.multi_tenant,
      version: v.ir.version,
      entity_count: v.ir.stats.entity_count,
      field_count: v.ir.stats.field_count,
      file_count: v.files.length,
    })),
  );
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Same three entities, three different domain declarations. Flip between them: `multi_tenant: true` auto-injects `tenant_id :binary_id` on every entity, rewrites indexes, scopes CRUD. `version “v2”` reroutes every emitted module through a V2 namespace so old and new APIs coexist."
  />

  <!-- Variant toggle + stats matrix -->
  <div class="px-6 pt-4 pb-3 border-b border-ink-800/60 space-y-3 shrink-0">
    <div class="flex gap-2 overflow-x-auto">
      {#each variants as v (v.id)}
        {@const active = v.id === selectedVariantId}
        <button
          type="button"
          onclick={() => selectVariant(v.id)}
          class="shrink-0 text-left p-3 rounded-lg border transition-all min-w-72
                 {active
            ? `border-${v.accent}/60 bg-ink-800/80 ring-1 ring-${v.accent}/30`
            : 'border-ink-700/70 bg-ink-900/40 hover:border-ink-600'}"
        >
          <div class="flex items-center gap-2 mb-1">
            <span class="h-1.5 w-1.5 rounded-full bg-{v.accent}"></span>
            <span
              class="text-[13px] font-medium {active
                ? `text-${v.accent}`
                : 'text-ink-100'}"
            >
              {v.title}
            </span>
          </div>
          <p class="text-[11px] text-ink-400 leading-relaxed line-clamp-3">
            {v.summary}
          </p>
        </button>
      {/each}
    </div>

    <!-- Stats matrix -->
    <div
      class="rounded-xl border border-ink-700/80 bg-ink-900/50 overflow-hidden"
    >
      <table class="w-full text-[12px]">
        <thead class="text-ink-500">
          <tr class="border-b border-ink-800/60">
            <th class="text-left px-3 py-2 font-normal uppercase tracking-widest text-[10px]"></th>
            {#each statsMatrix as row}
              <th
                class="text-left px-3 py-2 font-normal uppercase tracking-widest text-[10px] text-{row.accent}"
              >
                {row.title}
              </th>
            {/each}
          </tr>
        </thead>
        <tbody class="text-ink-300">
          <tr class="border-b border-ink-800/30">
            <td class="px-3 py-1.5 text-ink-500">multi_tenant</td>
            {#each statsMatrix as row}
              <td class="px-3 py-1.5">
                {#if row.multi_tenant}
                  <span class="text-reef">true</span>
                {:else}
                  <span class="text-ink-500">false</span>
                {/if}
              </td>
            {/each}
          </tr>
          <tr class="border-b border-ink-800/30">
            <td class="px-3 py-1.5 text-ink-500">version</td>
            {#each statsMatrix as row}
              <td class="px-3 py-1.5">
                <span class="{row.version ? 'text-sail' : 'text-ink-500'}">
                  {row.version ?? "—"}
                </span>
              </td>
            {/each}
          </tr>
          <tr class="border-b border-ink-800/30">
            <td class="px-3 py-1.5 text-ink-500">entities</td>
            {#each statsMatrix as row}
              <td class="px-3 py-1.5">{row.entity_count}</td>
            {/each}
          </tr>
          <tr class="border-b border-ink-800/30">
            <td class="px-3 py-1.5 text-ink-500">fields total</td>
            {#each statsMatrix as row}
              <td class="px-3 py-1.5">
                <span class="text-ink-100 font-semibold">{row.field_count}</span>
                {#if row.id !== "baseline"}
                  {@const base = statsMatrix[0]?.field_count ?? 0}
                  {#if row.field_count !== base}
                    <span
                      class="text-[10px] ml-1 {row.field_count > base
                        ? 'text-reef'
                        : 'text-coral'}"
                    >
                      ({row.field_count > base ? "+" : ""}{row.field_count - base}
                      vs baseline)
                    </span>
                  {/if}
                {/if}
              </td>
            {/each}
          </tr>
          <tr>
            <td class="px-3 py-1.5 text-ink-500">files generated</td>
            {#each statsMatrix as row}
              <td class="px-3 py-1.5">{row.file_count}</td>
            {/each}
          </tr>
        </tbody>
      </table>
    </div>
  </div>

  {#if selected}
    <div class="flex-1 min-h-0 grid grid-cols-12 gap-0">
      <!-- DSL source -->
      <section class="col-span-4 p-5 border-r border-ink-700/60 flex flex-col min-h-0">
        <div class="flex-1 min-h-0 flex flex-col">
          <CodeBlock
            code={selected.source}
            lang="elixir"
            filename={`lib/caravela_demo/domains/${selected.id}.ex`}
            annotations={[
              `multi_tenant: ${selected.ir.multi_tenant}`,
              selected.ir.version ? `version: "${selected.ir.version}"` : "no version",
            ]}
          />
        </div>
      </section>

      <!-- File browser -->
      <aside
        class="col-span-3 border-r border-ink-700/60 bg-ink-900/40 flex flex-col min-h-0"
      >
        <div
          class="px-4 py-3 border-b border-ink-700/60 flex items-center justify-between"
        >
          <span class="text-xs text-ink-400 uppercase tracking-widest">Generated files</span>
          <span class="text-[11px] text-ink-500">{selected.files.length}</span>
        </div>
        <FileTree
          files={selected.files}
          statuses={{}}
          selected={selectedFile}
          onSelect={selectFile}
        />
      </aside>

      <!-- Selected file -->
      <section class="col-span-5 p-5 flex flex-col min-h-0">
        {#if selectedFile}
          <div class="flex items-center gap-3 mb-3 shrink-0">
            <code class="text-[12px] text-ink-300 font-mono truncate flex-1">
              {selectedFile.path}
            </code>
            <span class="text-[11px] text-ink-500">
              {selectedFile.bytes} B · {selectedFile.language}
            </span>
          </div>
          <div class="flex-1 min-h-0 flex flex-col">
            <CodeBlock
              code={selectedFile.content}
              lang={selectedFile.language}
              filename=""
            />
          </div>
        {:else}
          <div class="flex-1 grid place-items-center text-ink-500 text-sm">
            Select a file on the left.
          </div>
        {/if}
      </section>
    </div>
  {/if}
</div>
