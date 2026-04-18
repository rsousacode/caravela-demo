import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import tailwindcss from "@tailwindcss/vite";
import path from "node:path";

export default defineConfig(({ mode }) => ({
  publicDir: "static",
  plugins: [
    svelte(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      $lib: path.resolve("./svelte/lib"),
    },
  },
  build: {
    target: "es2022",
    outDir: "../priv/static/assets",
    emptyOutDir: true,
    sourcemap: mode === "development",
    manifest: false,
    rollupOptions: {
      input: {
        app: "js/app.js",
      },
      output: {
        entryFileNames: "[name].js",
        chunkFileNames: "[name].js",
        assetFileNames: "[name][extname]",
      },
    },
  },
}));
