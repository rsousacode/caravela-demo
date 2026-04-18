# Bug & Improvements Report

Compiled after implementing phases 0–6 and starting phase 7 of the
stakeholder demo. Organized in four parts: **framework bugs** hit during
use, **framework API critique** (design observations where something
works but arguably shouldn't), **demo-app improvements** for what's
already built, and **known todos**.

Path: /Users/tahoe/Documents/Misc/Dev/Elixir/caravela_demo

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

### 2.8 LiveSvelte SSR conflicts with Shiki lazy-loaded grammars (Ignore)

Not a Caravela bug — this demo set `config :live_svelte, ssr: false`
because Shiki's dynamic-chunk language loading breaks under Node SSR.
Worth a note in
`/Users/tahoe/Documents/Misc/Dev/Elixir/caravela/docs/livesvelte.md`
about known incompatible Svelte libraries.
