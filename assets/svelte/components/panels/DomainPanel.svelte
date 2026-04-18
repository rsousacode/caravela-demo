<script>
  import PanelHeader from "../PanelHeader.svelte";
  import CodeBlock from "../CodeBlock.svelte";
  import EntityCard from "../EntityCard.svelte";
  import DomainERD from "../DomainERD.svelte";

  let { panel, domain } = $props();

  const ACCENTS = ["wave-400", "sail", "reef", "ember", "sand", "coral"];

  const stats = $derived([
    { label: "entities", value: domain.stats.entity_count },
    { label: "fields", value: domain.stats.field_count },
    { label: "relations", value: domain.stats.relation_count },
    { label: "hooks", value: domain.stats.hook_count },
    { label: "permissions", value: domain.stats.permission_count },
    {
      label: "mode",
      value: domain.multi_tenant ? "multi-tenant" : "single-tenant",
    },
  ]);
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="The Library domain is the single source of truth — parsed at compile time into an intermediate representation that every generator reads. Edit fields or relations here and the schema, migration, context, REST, GraphQL, LiveView, and typed Svelte components all regenerate in lockstep."
  />

  <div class="px-8 pt-4 pb-2 flex flex-wrap gap-3 border-b border-ink-800/60 shrink-0">
    <div
      class="text-[11px] text-ink-500 uppercase tracking-widest flex items-center gap-2"
    >
      <span class="h-1.5 w-1.5 rounded-full bg-reef animate-pulse"></span>
      live IR
    </div>
    <div class="text-[11px] text-ink-500">·</div>
    <div class="text-[11px] text-ink-400 font-mono">{domain.module}</div>
    {#if domain.version}
      <div class="text-[11px] text-ink-500">·</div>
      <div class="text-[11px] text-sail font-mono">version {domain.version}</div>
    {/if}
    <div class="flex-1"></div>
    <div class="flex items-center gap-4 text-[11px]">
      {#each stats as s}
        <div class="flex items-center gap-1.5">
          <span class="text-ink-500 uppercase tracking-widest">{s.label}</span>
          <span class="text-ink-100 font-semibold">{s.value}</span>
        </div>
      {/each}
    </div>
  </div>

  <div class="flex-1 min-h-0 overflow-auto p-6 grid grid-cols-12 gap-5">
    <section class="col-span-7 flex flex-col gap-5 min-h-0">
      <div class="min-h-105 flex flex-col">
        <CodeBlock
          code={domain.source}
          lang="elixir"
          filename="lib/caravela_demo/domains/library.ex"
          annotations={["compile-time", "DSL"]}
        />
      </div>

      <DomainERD entities={domain.entities} relations={domain.relations} />
    </section>

    <section class="col-span-5 space-y-4 min-h-0">
      <div class="space-y-3">
        {#each domain.entities as entity, i (entity.name)}
          <EntityCard {entity} accent={ACCENTS[i % ACCENTS.length]} />
        {/each}
      </div>

      {#if domain.relations.length}
        <div class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4 space-y-2.5">
          <div class="text-xs uppercase tracking-widest text-ink-500">Relations</div>
          {#each domain.relations as r}
            <div class="text-[13px] flex items-center gap-2 flex-wrap">
              <span class="text-ink-200 font-medium">{r.from}</span>
              <span
                class="text-[10px] uppercase tracking-widest text-ink-500 bg-ink-800 border border-ink-700 rounded px-1.5 py-0.5"
              >
                {r.type}
              </span>
              <span class="text-ink-500">→</span>
              <span class="text-ink-200 font-medium">{r.to}</span>
            </div>
          {/each}
        </div>
      {/if}

      <div class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4 space-y-2">
        <div class="text-xs uppercase tracking-widest text-ink-500">
          Downstream consumers
        </div>
        <div class="text-[12px] text-ink-400 leading-relaxed">
          The IR above drives <span class="text-wave-400">Ecto schemas</span>,
          <span class="text-sail">migrations</span>,
          <span class="text-reef">Phoenix contexts</span>,
          <span class="text-ember">JSON controllers</span>,
          <span class="text-sand">Absinthe/GraphQL types</span>,
          <span class="text-coral">LiveViews</span>, and typed
          <span class="text-wave-300">Svelte components</span>. Try the Generators
          panel next.
        </div>
      </div>
    </section>
  </div>
</div>
