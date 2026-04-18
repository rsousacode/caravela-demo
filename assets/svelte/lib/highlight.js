import { createHighlighter } from "shiki";

// Languages that the initial bundle loads. Only Shiki-supported grammars
// go here — unsupported ones (like `eex`, `svelte` — which is also absent
// from the default bundle) fall back to plain preformatted text.
const BUNDLED_LANGS = [
  "elixir",
  "typescript",
  "javascript",
  "json",
  "bash",
  "html",
];

const FALLBACK_LANG = "text";

const ALIAS = {
  heex: "elixir",
  eex: "elixir",
  svelte: "html",
};

let highlighterPromise = null;

export function getHighlighter() {
  if (!highlighterPromise) {
    highlighterPromise = createHighlighter({
      themes: ["one-dark-pro"],
      langs: BUNDLED_LANGS,
    }).catch((err) => {
      highlighterPromise = null;
      throw err;
    });
  }
  return highlighterPromise;
}

function resolveLang(lang) {
  if (!lang) return FALLBACK_LANG;
  const aliased = ALIAS[lang] ?? lang;
  return BUNDLED_LANGS.includes(aliased) ? aliased : FALLBACK_LANG;
}

function escape(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

export async function highlight(code, lang = "elixir") {
  try {
    const hl = await getHighlighter();
    return hl.codeToHtml(code, {
      lang: resolveLang(lang),
      theme: "one-dark-pro",
      transformers: [
        {
          pre(node) {
            node.properties.style = "background: transparent";
          },
        },
      ],
    });
  } catch (err) {
    console.warn("[highlight] falling back to plain text:", err);
    return `<pre><code>${escape(code)}</code></pre>`;
  }
}
