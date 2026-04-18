# Bug & Improvements Report

Compiled after implementing phases 0–6 and starting phase 7 of the
stakeholder demo. Organized in four parts: **framework bugs** hit during
use, **framework API critique** (design observations where something
works but arguably shouldn't), **demo-app improvements** for what's
already built, and **known todos**.

File paths under `lib/caravela/...` refer to the framework
(`../caravela`); paths under `lib/caravela_demo/...` refer to this demo
app.

---

## 1. Framework bugs

### 1.1 Generated form `mount/3` crashes with `KeyError :errors` — blocker

**Where:** `priv/templates/live_form_with_domain.eex` in the framework,
surfaced in `lib/caravela_demo_web/live/library/book_live/form.ex:29`
after running `mix caravela.gen.live --with-domain CaravelaDemo.Domains.Library`.

**What happens:** Navigate to `/library/books/new` (or any edit form).
The server raises:

```
** (KeyError) key :errors not found
    lib/caravela_demo_web/live/library/book_live/form_domain.ex:42: 
      anonymous fn/2 in FormDomain.__caravela_live_updater__/1
    lib/caravela/live/updater.ex:82: Caravela.Live.Updater.run/3
    lib/caravela_demo_web/live/library/book_live/form.ex:29:
      BookLive.Form.mount/3
```

**Root cause:** `use Caravela.Live.Template, domain: FormDomain` makes
`mount/3` `defoverridable` and injects a default that seeds the
domain's state via `Caravela.Live.Template.__assign_defaults__/2`. The
generated `form.ex` overrides `mount/3` completely without calling the
defaults first, so `socket.assigns` has no `:errors`, `:book`, `:attrs`,
etc. when `apply_updater(:load, {entity, attrs, errors})` fires.

**Fix (upstream):** The template should emit the defaults-seed line
before the first `apply_updater`:

```elixir
def mount(params, _session, socket) do
  defaults = unquote(form_domain_module).__caravela_live_state__()
  socket = Caravela.Live.Template.__assign_defaults__(socket, defaults)
  
  context = build_context(socket)
  {entity, attrs} = load_initial(params, context)
  # ... existing body
end
```

**Severity:** blocker. Every generated form is unusable until fixed.
I stopped work at this point so the demo's CRUD panel is currently unwired.

---

### 1.2 `Caravela.Flow.Runner` notify messages carry no sender tag

**Where:** `lib/caravela/flow/runner.ex` `send(notify, {:flow_state, _})` etc.

**What happens:** A process acting as `:notify` pid for N flows receives
a stream of `{:flow_state, _}` messages via raw `send/2`. `handle_info/2`
has no sender info, so the subscriber can't tell flows apart.

**Workaround in this demo:**
[lib/caravela_demo/flow_controller.ex](lib/caravela_demo/flow_controller.ex)
spawns a per-flow forwarder that re-emits messages as
`{:from_flow, flow_id, msg}`. Adds a process per running flow — trivial
overhead but architecturally unnecessary.

**Fix (upstream):** Include the flow's identity in the notify payload:

```elixir
defp notify(%{notify: pid, name: name}, msg), 
  do: send(pid, {:flow, name, msg})
```

Or take `:tag` as a start option and include it in every message.

**Severity:** design papercut. Works, just forces every non-trivial
caller to duplicate the demux boilerplate.

---

### 1.3 `Caravela.Flow.Runner.race_tasks/2` is "wait for all, take first" not "first wins"

**Where:** `lib/caravela/flow/runner.ex` `defp race_tasks`.

**What happens:** Uses `Task.yield_many(tasks, timeout)` which waits up
to `timeout` for ALL tasks, then picks the first with a value. If three
tasks finish at 100ms, 500ms, 5000ms with timeout 5000, the flow
advances at 5000ms — not 100ms.

**Fix (upstream):** Use `Task.await_any/2` (Elixir 1.17+) or a
selective-receive loop that resolves as soon as any task yields.

```elixir
defp race_tasks(tasks, timeout) do
  async = Enum.map(tasks, &Task.async/1)
  try do
    {:ok, Task.await_any(async, timeout)}
  rescue
    _ -> {:error, :race_timeout}
  after
    Enum.each(async, &Task.shutdown(&1, :brutal_kill))
  end
end
```

**Severity:** demo-visible. In my smoke test, the RaceFlow ended
correctly but took the full slow-task duration instead of showing
"first back wins" behavior.

---

### 1.4 Generated context module has unreachable clauses (warnings every compile)

**Where:** `Caravela.Gen.Context` template, surfaces in any
`mix caravela.gen.context` output.

**What happens:** Three dialyzer warnings per compile of
`lib/caravela_demo/library.ex`:

```
warning: the following clause will never match: false
  at lib/caravela_demo/library.ex:199  (authorize_create/2)
  at lib/caravela_demo/library.ex:211  (authorize_update/3)
  at lib/caravela_demo/library.ex:223  (authorize_delete/3)

warning: the following clause will never match: {:error, _} = err
  at lib/caravela_demo/library.ex:234  (run_delete_hook/3)
```

**Root cause:** The permission-check lookup
`__caravela_permission__(:can_create, ...)` has a fallback that always
returns `true` when no `can_*` rule is declared. Elixir's type checker
sees the narrowed type and flags the `false -> :unauthorized` branch as
dead. Same for the `on_delete` hook fallback returning `:ok`.

**Fix (upstream):** Template should detect "no permissions for this
entity" and emit a simpler function without the defensive `false`
clause. Same for hooks.

**Severity:** noisy, non-fatal. Every fresh CRUD gen produces warnings,
which makes users wonder if they forgot to declare something.

---

### 1.5 `Caravela.Gen.SvelteForm` uses Svelte 4 event syntax

**Where:** `lib/caravela/gen/svelte_form.ex` `form_input_control/3`.

**What happens:** Templates emit

```svelte
<input on:change={(e) => handleChange(...)} />
```

Svelte 5 (what LiveSvelte 0.18 ships with, and what this demo uses)
uses plain attribute syntax: `onchange={...}`. The old `on:change:`
directive still works in Svelte 5 but is deprecated and produces
warnings at build time.

**Fix (upstream):** Replace `on:<event>={...}` → `on<event>={...}` in
`svelte_form.ex` templates.

**Severity:** low. Still functions; emits deprecation warnings.

---

### 1.6 `mix caravela.gen.schema` migration timestamp = wall clock (undocumented pin)

**Where:** `lib/caravela/gen/migration.ex` `render/2`.

**What happens:** Each run stamps the current UTC as the migration
prefix, so snapshot tests always diff as "add + remove" instead of
"unchanged" unless you pin the timestamp.

**Workaround in this demo:**
[lib/caravela_demo_web/generator_runner.ex](lib/caravela_demo_web/generator_runner.ex)
passes `timestamp: "00000000000000"` to `Migration.render/2`.

**Fix (upstream):** Document the `:timestamp` option, or add a
`--deterministic` CLI flag that sets it for snapshot contexts. Without
this, Caravela is effectively unsnapshotable out of the box.

**Severity:** low. Option exists, just isn't advertised.

---

## 2. Framework API critique

### 2.1 Module-naming split: `Domains.Library` ≠ `Library`

The domain DSL module is `CaravelaDemo.Domains.Library`, but the
generated Ecto schemas live at `CaravelaDemo.Library.Book`, the context
at `CaravelaDemo.Library`, the controllers at
`CaravelaDemoWeb.BookController`, the LiveViews at
`CaravelaDemoWeb.Library.BookLive.*`. Five different namespaces derived
from one domain declaration.

The `.Domains.Library` prefix feels like Elixir-team noise — new users
expect "everything for Library lives at `CaravelaDemo.Library.*`".
Moving the domain DSL into `CaravelaDemo.Library.Domain` and collocating
it with the generated code would halve the cognitive load.

---

### 2.2 `Caravela.Live.Form` — `errors` and `async_errors` as separate maps

The form UI has to track two error maps:

- `errors` populated by synchronous changeset validation
- `async_errors` populated by `validate_async` dispatch

There's no unified "field X is currently in error (for whatever reason)"
query. A form panel (see
[FormsPanel.svelte](assets/svelte/components/panels/FormsPanel.svelte))
renders them separately and has to remember which source fills which
map.

Merging into one shape would simplify every caller:

```elixir
# Proposed: single errors map with tagged messages
%{isbn: {:async, "checksum failed"}, title: {:sync, "required"}}
```

---

### 2.3 `updater :name, fn ... end` requires literal fn; captures rejected

The DSL performs AST-based arity detection. Both of these fail at
compile time:

```elixir
updater :set_book, &MyMod.update_book/2   # ❌ "expects a function literal"
updater :save, fn s -> save(s) end          # ✅ OK
```

Real codebases pass updater funs around and compose them — rejecting
captures forces a wrapping `fn`. Either accept `&`-captures (arity is
knowable via `:erlang.fun_info/1`) or the error message should hint at
the workaround.

Saw this hit in
[lib/caravela_demo_web/form_panel.ex](lib/caravela_demo_web/form_panel.ex)
which uses helper funs instead of updaters specifically to dodge this.

---

### 2.4 `Caravela.Flow` — signals are anonymous funs, undiscoverable

`Caravela.Flow.signal(pid, fn state -> ... end)` lets the caller mutate
state freely. No way to:
- Enumerate what signals a flow accepts
- Validate that a call matches a known shape
- Generate a UI from declared signals

My demo works around this with a separate
[Flows catalog](lib/caravela_demo/flows.ex) that maps string ids to
state-mutating funs. A framework-native declarative option:

```elixir
flow :sync, initial_state: ... do
  signal :mark_dirty, fn state -> %{state | dirty: true} end
  signal :set_book, fn state, payload -> %{state | book_id: payload.id} end
  
  repeat do
    ...
  end
end
```

Then `Caravela.Flow.__caravela_signals__/1` returns the list for
introspection, and `Caravela.Flow.signal(pid, :mark_dirty)` dispatches
by name.

---

### 2.5 `mix caravela.gen.live` doesn't auto-insert routes

The generator prints the route snippet and expects the user to paste it
into `router.ex`:

```
Next steps:
  ...
  4. Paste the router snippet above into lib/<app>_web/router.ex.
```

A marker-based auto-insertion (like the `# --- CUSTOM ---` pattern) in
router.ex would remove a manual step and reduce "it's broken, did I
paste correctly?" support load. Or just generate a dedicated
`router_caravela.ex` to `import Phoenix.Router` into.

---

### 2.6 Snapshot vs "live" generator output isn't meaningful

My plan document initially suggested the demo needed `System.cmd` for
live output and pre-rendered snapshots for web. Actually `Caravela.Gen.*`
render functions are pure — there's no point in the distinction. The
only role a committed snapshot plays is as a diff baseline.

This should be documented in
`/Users/tahoe/Documents/Misc/Dev/Elixir/caravela/docs/generators.md`:
"All render functions are pure. You can call them anywhere that has
access to the compiled domain module — no filesystem mutation, no Mix
process needed. The Mix tasks are a thin CLI wrapper."

---

### 2.7 `# --- CUSTOM ---` marker leaks across rename

If you write code below the marker in `library/book.ex`, then rename
the domain module (say, split into `LibraryV1` and `LibraryV2`),
regenerating creates new files but the old `library/book.ex` with your
custom code stays orphaned. No warning, no `--clean` flag.

---

### 2.8 LiveSvelte SSR conflicts with Shiki lazy-loaded grammars

Not a Caravela bug — this demo set `config :live_svelte, ssr: false`
because Shiki's dynamic-chunk language loading breaks under Node SSR.
Worth a note in
`/Users/tahoe/Documents/Misc/Dev/Elixir/caravela/docs/livesvelte.md`
about known incompatible Svelte libraries.

---

## 3. Demo-app improvements

### 3.1 Shiki ships every language chunk (noisy builds, 800 KB `emacs-lisp.js`)

**Where:**
[assets/svelte/lib/highlight.js](assets/svelte/lib/highlight.js) uses
`createHighlighter` from `shiki` which lazy-imports every language
grammar. Vite generates a chunk per language even though we only use 6.

**Fix:** Switch to `createHighlighterCore` with explicit lang imports:

```js
import { createHighlighterCore } from "shiki/core";
import { createOnigurumaEngine } from "shiki/engine/oniguruma";
import elixir from "@shikijs/langs/elixir";
import ts from "@shikijs/langs/typescript";
// etc.
```

Saves ~2 MB of chunk output. Initial payload unchanged (chunks are
lazy) but the build noise disappears.

---

### 3.2 VariantRunner recomputes 90 files on every mount (~400 ms)

**Where:**
[lib/caravela_demo_web/variant_runner.ex](lib/caravela_demo_web/variant_runner.ex)
`all/0` runs `GeneratorRunner.run_one("all", module)` for every variant
on every LiveView mount.

**Fix:** Cache via `:persistent_term`. The three variants are static
module references; cache can be invalidated by hot-reload in dev.

```elixir
def all do
  case :persistent_term.get({__MODULE__, :cache}, nil) do
    nil ->
      result = Enum.map(@variants, &serialize/1)
      :persistent_term.put({__MODULE__, :cache}, result)
      result
    cached -> cached
  end
end
```

Reduces mount time by ~300ms.

---

### 3.3 Props payload is ~630 KB (uncompressed)

Every LiveView mount ships:
- 3 variants × 30 files of content ≈ 270 KB
- 6 generators × ~30 files + baselines ≈ 240 KB
- domain IR + flow trees + runtime state ≈ 30 KB

Gzips to ~180 KB — acceptable for a demo — but every page refresh pays
this. Options:
- Lazy-load panel data on navigate (only send what's needed)
- `Phoenix.LiveView.stream/3` for file lists
- Skip content when baseline path matches current path (dedupe)

Worth doing if this demo ever hosts on Fly with real latency.

---

### 3.4 Round-trip log component is near-duplicated 3 times

[FormsPanel.svelte](assets/svelte/components/panels/FormsPanel.svelte)'s
log panel, [FlowEventLog.svelte](assets/svelte/components/flows/FlowEventLog.svelte),
and [TraceLog.svelte](assets/svelte/components/runtime/TraceLog.svelte)
all implement the same "timestamped event log" pattern with slight
visual differences. Factor into a single `<EventLog>` component taking
`{entries, columnRenderer, kindColorMap}`.

---

### 3.5 No live domain-editor

The domain source viewer is read-only. The most impressive "wow" for
stakeholders would be: edit
[lib/caravela_demo/domains/library.ex](lib/caravela_demo/domains/library.ex)
in a Monaco editor inside the panel, and watch every downstream layer
regenerate in real-time (Ecto schema, migration, TS types, GraphQL
schema, LiveView forms).

Technically hard (server-side compile-into-isolated-module, hot-swap,
fall back on error), but the payoff is huge. A scaled-down version:
preset "tweaks" (buttons that mutate the domain in specific ways —
"add :page_count", "make :isbn required", "add relation authors ↔ books
many-to-many") and re-run the generator output.

---

### 3.6 Flow state "scrubber" / history timeline

Currently the flow state is always "live now". A user who joins a
running debounce flow mid-cycle has no way to see the signal bursts
that preceded their view.

Add a history buffer to the flow panel (the server-side
[flow_store.js](assets/svelte/lib/flow_store.js) already keeps a 100-
entry log, but the state tree doesn't step backward). A timeline
slider that lets the user scrub through past states would make
debouncing visually obvious.

---

### 3.7 FlowsPanel DAG is linear

Currently renders step trees top-to-bottom as an indented list.
Branching flows (sequences with conditional `run` returns) would look
cramped. A real graph layout (ReactFlow / svelte-flow) with actual
edges would scale better.

---

### 3.8 FormPanel `:save` is simulated, not persisted

[FormPanel.save/1](lib/caravela_demo_web/form_panel.ex) sleeps 500ms
and sets `"Saved (simulated)"`. The real
`CaravelaDemo.Library.create_book/2` context function exists (generated
by `mix caravela.gen.context`) — it could actually persist. Would
require Decimal coercion for `:price` from the string input.

---

### 3.9 CRUD panel doesn't exist

The `/library/books`, `/library/authors`, `/library/publishers` routes
are wired and live (modulo bug §1.1), but the Command Center's CRUD
panel still shows the PlaceholderPanel. Intended design: embed or link
to the generated LiveViews with a seed-count badge and
"Open full page" link. Stopped here when form bug hit.

---

### 3.10 Shared `FileBrowser` component

Both [GeneratorsPanel](assets/svelte/components/panels/GeneratorsPanel.svelte)
and [TenancyPanel](assets/svelte/components/panels/TenancyPanel.svelte)
render the same three-part layout: category toggle on top, file tree
on the side, code viewer + diff on the right. They share only
[FileTree.svelte](assets/svelte/components/FileTree.svelte). Factor the
whole layout into `<FileBrowser>` and pass in the specific top strip.

---

### 3.11 Error boundaries

If a LiveView handler crashes, Phoenix restarts the socket silently.
The Svelte UI has no knowledge. Add a top-level error handler in
[App.svelte](assets/svelte/App.svelte) that listens for socket
reconnect events and shows a banner.

---

### 3.12 Accessibility

No keyboard navigation for the sidebar, no focus management when
switching panels, few aria labels. Default browser tab order works but
the "CLEAN" / "modified" status pills in GeneratorsPanel aren't read by
screen readers.

---

### 3.13 Dev hot-reload of Svelte assets

Vite runs in watch mode via the `:watchers` config in
[config/dev.exs](config/dev.exs), but Phoenix doesn't notify LiveView
of `.svelte` changes. Page refresh required for Svelte edits. Adding
the svelte build dir to `:live_reload` `:patterns` would fix it.

---

## 4. Known todos

Things I meant to do but didn't.

- **CRUD panel** (Phase 7, second half). Blocked on §1.1; will unblock
  after patching the template upstream or monkeypatching the generated
  form.ex in this demo.
- **ERD on Domain panel** uses a custom SVG layout. A proper library
  (svelte-flow) would handle circular/complex relation graphs.
- **"Run live generator" button** in GeneratorsPanel — originally in
  the Phase 3 plan. Render functions are pure so we could skip
  `System.cmd` and just call them on demand from the panel. Didn't get
  to it because the baseline always-correct output is sufficient for
  the stakeholder pitch.
- **Presentation mode** (F11 style, hide sidebar, big text, hide fake
  terminal header). Useful for the live demo walkthrough.
- **Onboarding tour** (Shepherd.js overlay explaining each panel on
  first visit).

---

## 5. Summary

| Category | Count |
| --- | --- |
| Framework bugs (code) | 6 |
| Framework API critique | 8 |
| Demo-app improvements | 13 |
| Open todos | 5 |

**Most urgent:** §1.1 (form mount crash) blocks every generated CRUD
form. Everything else is stylistic or optimization.

**Highest-leverage upstream fix:** §2.4 (declarative flow signals).
Changes the demo from "here's a catalog of flows with ad-hoc buttons"
to "here's a framework that tells the UI what it accepts," which
justifies far more of the declarative value proposition.

**Demo polish most worth doing next:** §3.5 (live domain editor) for
presentation punch, §3.1 (Shiki trim) for build hygiene, §3.9 (CRUD
panel) to close Phase 7.
