<script>
  import { highlight } from "$lib/highlight.js";

  let { code = "", lang = "elixir", filename = "", annotations = [] } = $props();

  let html = $state("");
  let loading = $state(true);

  $effect(() => {
    loading = true;
    highlight(code, lang)
      .then((h) => {
        html = h;
      })
      .catch((err) => {
        html = `<pre class="text-coral">${err.message}</pre>`;
      })
      .finally(() => {
        loading = false;
      });
  });

  async function copy() {
    try {
      await navigator.clipboard.writeText(code);
    } catch {}
  }
</script>

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-hidden flex flex-col min-h-0">
  {#if filename}
    <div
      class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between shrink-0"
    >
      <span class="text-xs text-ink-400 uppercase tracking-widest">{filename}</span>
      <div class="flex items-center gap-3">
        {#if annotations.length}
          <div class="flex gap-1.5">
            {#each annotations as a}
              <span
                class="text-[10px] uppercase tracking-widest text-ink-300 bg-ink-800 border border-ink-700 rounded px-1.5 py-0.5"
                >{a}</span
              >
            {/each}
          </div>
        {/if}
        <button
          type="button"
          onclick={copy}
          class="text-[11px] text-ink-500 hover:text-wave-400 transition-colors"
          title="Copy source"
        >
          copy
        </button>
      </div>
    </div>
  {/if}

  <div class="flex-1 min-h-0 overflow-auto text-[13px] leading-6 p-5 code-block-inner">
    {#if loading}
      <pre class="text-ink-500 animate-pulse">loading highlighter…</pre>
    {:else}
      {@html html}
    {/if}
  </div>
</div>

<style>
  .code-block-inner :global(pre) {
    margin: 0;
    background: transparent !important;
  }
  .code-block-inner :global(code) {
    font-family: inherit;
  }
</style>
