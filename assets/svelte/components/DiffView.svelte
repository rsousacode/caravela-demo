<script>
  import { diffLines } from "$lib/diff.js";

  let { baseline = "", current = "" } = $props();

  const rows = $derived(diffLines(baseline, current));

  const stats = $derived.by(() => {
    let add = 0, rem = 0;
    for (const r of rows) {
      if (r.kind === "add") add++;
      else if (r.kind === "remove") rem++;
    }
    return { add, rem };
  });
</script>

<div class="flex-1 min-h-0 overflow-auto text-[12px] leading-5 font-mono">
  <div
    class="px-4 py-2 sticky top-0 bg-ink-900/90 backdrop-blur border-b border-ink-700/60 text-[11px] flex items-center gap-4"
  >
    <span class="text-ink-500 uppercase tracking-widest">diff</span>
    <span class="text-reef">+{stats.add}</span>
    <span class="text-coral">−{stats.rem}</span>
    <span class="text-ink-600 ml-auto">{rows.length} lines</span>
  </div>

  <table class="w-full border-collapse">
    <tbody>
      {#each rows as r, i (i)}
        <tr
          class={r.kind === "add"
            ? "bg-reef/5"
            : r.kind === "remove"
              ? "bg-coral/5"
              : ""}
        >
          <td class="w-12 text-right pr-2 text-ink-600 select-none">{r.oldNo ?? ""}</td>
          <td class="w-12 text-right pr-2 text-ink-600 select-none">{r.newNo ?? ""}</td>
          <td
            class="w-4 text-center select-none {r.kind === 'add'
              ? 'text-reef'
              : r.kind === 'remove'
                ? 'text-coral'
                : 'text-ink-700'}"
          >
            {r.kind === "add" ? "+" : r.kind === "remove" ? "−" : " "}
          </td>
          <td
            class="pl-2 pr-4 whitespace-pre {r.kind === 'add'
              ? 'text-ink-50'
              : r.kind === 'remove'
                ? 'text-ink-300'
                : 'text-ink-400'}"
          >
            {r.line}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
</div>
