<script>
  import PanelHeader from "../PanelHeader.svelte";

  let { panel } = $props();
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="The Library domain is the single source of truth. Entities, fields, and relations here drive every generator downstream — Ecto, Phoenix contexts, JSON API, GraphQL, LiveView, and typed Svelte components."
  />

  <div class="flex-1 overflow-auto p-8 grid grid-cols-12 gap-6">
    <section class="col-span-7 space-y-4">
      <div
        class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden"
      >
        <div class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between">
          <span class="text-xs text-ink-400 uppercase tracking-widest">
            lib/caravela_demo/domains/library.ex
          </span>
          <span class="text-[11px] text-ink-500">placeholder · Phase 2 wires live IR</span>
        </div>
        <pre class="text-[13px] leading-6 text-ink-200 p-5 overflow-auto"><code>defmodule CaravelaDemo.Domains.Library do
  use Caravela.Domain

  entity :authors do
    field :name, :string, required: true
    field :bio, :text
    field :born, :date
  end

  entity :books do
    field :title, :string, required: true, min_length: 3
    field :isbn, :string, format: ~r/^\d{13}$/
    field :published, :boolean, default: false
    field :price, :decimal, precision: 10, scale: 2
  end

  entity :publishers do
    field :name, :string, required: true
    field :country, :string
  end

  relation :authors, :books, type: :has_many
  relation :books, :publishers, type: :belongs_to
end</code></pre>
      </div>
    </section>

    <section class="col-span-5 space-y-4">
      <div class="grid grid-cols-1 gap-3">
        {#each [{ name: "authors", fields: 3, color: "wave-400" }, { name: "books", fields: 4, color: "sail" }, { name: "publishers", fields: 2, color: "reef" }] as entity}
          <div
            class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4 hover:border-{entity.color}/40 transition-colors"
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="h-2 w-2 rounded-full bg-{entity.color}"></span>
                <span class="text-ink-100 font-medium">{entity.name}</span>
              </div>
              <span class="text-[11px] text-ink-500">{entity.fields} fields</span>
            </div>
            <div class="mt-2 text-[11px] text-ink-400">
              Entity · binary_id primary key · auto-migrated
            </div>
          </div>
        {/each}
      </div>

      <div
        class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4 space-y-2"
      >
        <div class="text-xs uppercase tracking-widest text-ink-500">Relations</div>
        <div class="text-sm text-ink-200">
          <span class="text-wave-400">authors</span>
          <span class="text-ink-500"> — has_many → </span>
          <span class="text-sail">books</span>
        </div>
        <div class="text-sm text-ink-200">
          <span class="text-sail">books</span>
          <span class="text-ink-500"> — belongs_to → </span>
          <span class="text-reef">publishers</span>
        </div>
      </div>
    </section>
  </div>
</div>
