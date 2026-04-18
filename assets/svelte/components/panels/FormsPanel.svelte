<script>
  import PanelHeader from "../PanelHeader.svelte";

  let { panel, form, live } = $props();

  const ROLE_ACCENT = {
    anon: "ink-400",
    editor: "wave-400",
    admin: "ember",
  };

  const role = $derived(form?.current_user?.role ?? "anon");
  const attrs = $derived(form?.attrs ?? {});
  const visibility = $derived(form?.field_visibility ?? {});
  const errors = $derived(form?.errors ?? {});
  const asyncErrors = $derived(form?.async_errors ?? {});
  const meta = $derived(form?.meta ?? { visible_fields: [], async_fields: [], debounces: {} });
  const debounces = $derived(meta.debounces ?? {});
  const roles = $derived(form?.roles ?? []);
  const log = $derived(form?.log ?? []);

  // Client-side debounce of async validation pushes
  const asyncTimers = new Map();

  function setRole(r) {
    live?.pushEvent("form:set_role", { role: r });
  }

  function pushChange(field, value) {
    live?.pushEvent("form:change", { field, value });

    if (meta.async_fields.includes(field)) {
      const delay = debounces[field] ?? 0;
      const prev = asyncTimers.get(field);
      if (prev) clearTimeout(prev);
      const timer = setTimeout(() => {
        live?.pushEvent("form:validate_async", { field, value });
        asyncTimers.delete(field);
      }, delay);
      asyncTimers.set(field, timer);
    }
  }

  function onText(field, e) {
    pushChange(field, e.currentTarget.value);
  }

  function onBool(field, e) {
    pushChange(field, e.currentTarget.checked);
  }

  function save() {
    live?.pushEvent("form:save", {});
  }

  function reset() {
    live?.pushEvent("form:reset", {});
  }

  function isAsyncField(name) {
    return meta.async_fields?.includes(name);
  }

  function isGated(name) {
    return meta.visible_fields?.includes(name);
  }

  function isVisible(name) {
    return !isGated(name) || visibility[name] === true;
  }

  function formatTime(ms) {
    const d = new Date(ms);
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(d.getSeconds()).padStart(2, "0")}.${String(d.getMilliseconds()).padStart(3, "0")}`;
  }

  const LOG_COLOR = {
    set_role: "text-sail",
    change: "text-ink-300",
    "→ validate_async": "text-ember",
    "… stale": "text-ink-500",
    "← async ok": "text-reef",
    "← async error": "text-coral",
    save: "text-sand",
    "← save done": "text-wave-400",
    reset: "text-ink-400",
  };
</script>

<div class="h-full flex flex-col">
  <PanelHeader
    {panel}
    subtitle="Declare visibility predicates and async validators on the server with Caravela.Live.Form. The role toggle re-runs the predicates on every change — the `price` field literally disappears for anonymous users. ISBN validation is server-side with a 500ms debounce (try 9780262035613 for a pass, change a digit for a fail)."
  />

  <div class="flex-1 min-h-0 grid grid-cols-12 gap-0">
    <!-- Left: controls + form -->
    <section class="col-span-8 p-6 overflow-auto flex flex-col gap-5 border-r border-ink-700/60">
      <!-- Role toggle -->
      <div
        class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4 flex items-center gap-4"
      >
        <div class="flex-1 min-w-0">
          <div class="text-xs uppercase tracking-widest text-ink-500">Current user</div>
          <div class="text-[13px] text-ink-100 mt-0.5">
            {form?.current_user?.name ?? "Anonymous"}
            <span class="text-ink-500">
              · role=<span class="text-{ROLE_ACCENT[role] ?? 'ink-300'}">{role}</span>
            </span>
          </div>
        </div>
        <div class="flex rounded-lg overflow-hidden border border-ink-700">
          {#each roles as r (r.id)}
            {@const active = r.id === role}
            <button
              type="button"
              onclick={() => setRole(r.id)}
              class="px-3 py-1.5 text-[12px] transition-colors
                     {active
                ? `bg-${ROLE_ACCENT[r.id] ?? 'ink-400'}/15 text-${ROLE_ACCENT[r.id] ?? 'ink-200'}`
                : 'text-ink-400 hover:text-ink-200'}"
            >
              {r.id}
            </button>
          {/each}
        </div>
      </div>

      <!-- Form -->
      <form
        class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-5 space-y-4"
        onsubmit={(e) => (e.preventDefault(), save())}
      >
        <div class="flex items-center justify-between">
          <div>
            <div class="text-[13px] text-ink-100 font-medium">Book</div>
            <code class="text-[11px] text-ink-500">{meta.entity}</code>
          </div>
          {#if form?.flash_message}
            <div class="text-[12px] text-reef">{form.flash_message}</div>
          {/if}
        </div>

        <!-- title (always visible, sync-validated) -->
        <div class="space-y-1">
          <label class="flex items-baseline gap-2 text-[12px] text-ink-300">
            <span>Title</span>
            <span class="text-[10px] uppercase tracking-wider text-ember">required</span>
            <span class="text-[10px] text-ink-500">min 3</span>
          </label>
          <input
            type="text"
            value={attrs.title ?? ""}
            oninput={(e) => onText("title", e)}
            placeholder="The Phoenix Project"
            class="w-full bg-ink-950 border border-ink-700 rounded-lg px-3 py-2 text-[13px] text-ink-100 focus:outline-none focus:border-wave-400/60"
          />
          {#if errors.title}
            <div class="text-[11px] text-coral">{errors.title}</div>
          {/if}
        </div>

        <!-- isbn (async-validated, debounced) -->
        <div class="space-y-1">
          <label class="flex items-baseline gap-2 text-[12px] text-ink-300">
            <span>ISBN</span>
            <span class="text-[10px] text-ember">async</span>
            <span class="text-[10px] text-ink-500">debounce {debounces.isbn ?? 0}ms</span>
            <span class="flex-1"></span>
            {#if asyncErrors.isbn}
              <span class="text-[11px] text-coral">{asyncErrors.isbn}</span>
            {:else if attrs.isbn && attrs.isbn.length === 13}
              <span class="text-[11px] text-reef">✓ checksum ok</span>
            {/if}
          </label>
          <input
            type="text"
            value={attrs.isbn ?? ""}
            oninput={(e) => onText("isbn", e)}
            placeholder="9780262035613"
            maxlength="13"
            class="w-full bg-ink-950 border rounded-lg px-3 py-2 text-[13px] text-ink-100 focus:outline-none font-mono
                   {asyncErrors.isbn
              ? 'border-coral/60 focus:border-coral/80'
              : 'border-ink-700 focus:border-wave-400/60'}"
          />
        </div>

        <!-- published (boolean, toggles publish_at visibility) -->
        <div class="flex items-center gap-3">
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={attrs.published === true}
              onchange={(e) => onBool("published", e)}
              class="accent-wave-400"
            />
            <span class="text-[13px] text-ink-200">Published</span>
          </label>
          <span class="text-[11px] text-ink-500">
            ← toggles visibility of
            <code class="text-ink-400">publish_at</code>
          </span>
        </div>

        <!-- publish_at (gated by `published`) -->
        {#if isVisible("publish_at")}
          <div class="space-y-1 border-l-2 border-sail/40 pl-3">
            <label class="flex items-baseline gap-2 text-[12px] text-ink-300">
              <span>Publish at</span>
              <span class="text-[10px] uppercase tracking-wider text-sail">visible</span>
              <code class="text-[10px] text-ink-500"
                >when attrs.published == true</code
              >
            </label>
            <input
              type="date"
              value={attrs.publish_at ?? ""}
              oninput={(e) => onText("publish_at", e)}
              class="bg-ink-950 border border-ink-700 rounded-lg px-3 py-2 text-[13px] text-ink-100 focus:outline-none focus:border-sail/60"
            />
          </div>
        {/if}

        <!-- price (gated by role ∈ admin/editor) -->
        {#if isVisible("price")}
          <div class="space-y-1 border-l-2 border-ember/40 pl-3">
            <label class="flex items-baseline gap-2 text-[12px] text-ink-300">
              <span>Price</span>
              <span class="text-[10px] uppercase tracking-wider text-ember">visible</span>
              <code class="text-[10px] text-ink-500">when role ∈ [:admin, :editor]</code>
            </label>
            <input
              type="number"
              step="0.01"
              value={attrs.price ?? ""}
              oninput={(e) => onText("price", e)}
              placeholder="29.99"
              class="bg-ink-950 border border-ink-700 rounded-lg px-3 py-2 text-[13px] text-ink-100 focus:outline-none focus:border-ember/60 w-40"
            />
          </div>
        {:else}
          <div class="border-l-2 border-ink-800 pl-3 text-[11px] text-ink-600 italic">
            price — hidden (role={role}); the DOM never sees it, not a CSS hide
          </div>
        {/if}

        <!-- Buttons -->
        <div class="flex items-center gap-2 pt-3 border-t border-ink-800/60">
          <button
            type="submit"
            disabled={form?.saving}
            class="px-4 py-1.5 text-[12px] border border-wave-400/50 text-wave-400 rounded-lg hover:bg-wave-400/10 disabled:opacity-50"
          >
            {form?.saving ? "saving…" : "save"}
          </button>
          <button
            type="button"
            onclick={reset}
            class="px-3 py-1.5 text-[12px] border border-ink-700 text-ink-400 rounded-lg hover:text-ink-200"
          >
            reset
          </button>
          <span class="flex-1"></span>
          <span class="text-[11px] text-ink-500">
            {Object.keys(errors).length + Object.keys(asyncErrors).length} issue{Object.keys(errors).length + Object.keys(asyncErrors).length === 1 ? "" : "s"}
          </span>
        </div>
      </form>

      <!-- Field visibility matrix -->
      <div class="rounded-xl border border-ink-700/80 bg-ink-900/60 p-4">
        <div class="text-xs uppercase tracking-widest text-ink-500 mb-3">Visibility matrix</div>
        <div class="grid grid-cols-2 gap-x-6 gap-y-1.5 text-[12px]">
          {#each meta.visible_fields ?? [] as f}
            {@const ok = visibility[f] === true}
            <div class="flex items-center gap-2">
              <span
                class="h-1.5 w-1.5 rounded-full {ok ? 'bg-reef' : 'bg-ink-700'}"
              ></span>
              <code class="text-ink-300">{f}</code>
              <span class="flex-1"></span>
              <span class="{ok ? 'text-reef' : 'text-ink-500'}">
                {ok ? "visible" : "hidden"}
              </span>
            </div>
          {/each}
          {#each meta.async_fields ?? [] as f}
            <div class="flex items-center gap-2">
              <span class="h-1.5 w-1.5 rounded-full bg-ember"></span>
              <code class="text-ink-300">{f}</code>
              <span class="flex-1"></span>
              <span class="text-ember">async · {debounces[f]}ms</span>
            </div>
          {/each}
        </div>
      </div>
    </section>

    <!-- Right: round-trip log -->
    <aside class="col-span-4 flex flex-col min-h-0">
      <div
        class="px-4 py-3 border-b border-ink-700/60 flex items-center justify-between shrink-0"
      >
        <span class="text-xs text-ink-400 uppercase tracking-widest">Round-trip log</span>
        <span class="text-[11px] text-ink-500">{log.length}</span>
      </div>
      <div class="overflow-auto flex-1 font-mono text-[11.5px]">
        {#if log.length === 0}
          <div class="p-4 text-ink-500 italic">
            no events yet — type in a field or flip the role toggle
          </div>
        {:else}
          <ul class="divide-y divide-ink-800/60">
            {#each log as entry, idx (entry.at + "-" + idx)}
              <li class="px-3 py-1.5 flex items-start gap-2.5">
                <span class="text-ink-600 shrink-0 w-24">{formatTime(entry.at)}</span>
                <span
                  class="shrink-0 w-28 {LOG_COLOR[entry.label] ?? 'text-ink-400'}"
                >
                  {entry.label}
                </span>
                <span class="flex-1 text-ink-300 break-all">{entry.detail}</span>
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    </aside>
  </div>
</div>
