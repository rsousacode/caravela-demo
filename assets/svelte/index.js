// Central registry of every Svelte component LiveSvelte may mount.
//
// The Command Center shell lives at `App`. Every generated Library
// component (BookIndex, AuthorShow, PublisherForm, …) is bulk-imported
// from `./library/` via Vite's glob so re-running `mix caravela.gen.live`
// picks up automatically without edits here.
import App from "./App.svelte";

const modules = import.meta.glob("./library/*.svelte", { eager: true });

const libraryComponents = Object.fromEntries(
  Object.entries(modules).map(([path, mod]) => {
    // "./library/BookIndex.svelte" -> "library/BookIndex"
    const name = path.replace(/^\.\//, "").replace(/\.svelte$/, "");
    return [name, mod.default];
  }),
);

export default {
  App,
  ...libraryComponents,
};
