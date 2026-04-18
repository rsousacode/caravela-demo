
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
