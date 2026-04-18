import { createHighlighter } from "shiki";

let highlighterPromise = null;

export function getHighlighter() {
  if (!highlighterPromise) {
    highlighterPromise = createHighlighter({
      themes: ["one-dark-pro"],
      langs: ["elixir", "eex", "typescript", "json", "bash"],
    });
  }
  return highlighterPromise;
}

export async function highlight(code, lang = "elixir") {
  const hl = await getHighlighter();
  return hl.codeToHtml(code, {
    lang,
    theme: "one-dark-pro",
    transformers: [
      {
        pre(node) {
          node.properties.style = "background: transparent";
        },
      },
    ],
  });
}
