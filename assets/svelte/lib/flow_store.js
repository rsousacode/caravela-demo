// Client-side store for live flow events coming off the LiveView socket.
// Keyed by catalog flow id; each entry carries status, latest state, and
// a bounded event log so the panel can re-render without polling.

import { SvelteMap } from "svelte/reactivity";

const MAX_LOG = 100;

function blank() {
  return { status: "idle", state: null, startedAt: null, log: [] };
}

export function createFlowStore(initialSnapshot = {}) {
  const map = new SvelteMap();

  for (const [id, snap] of Object.entries(initialSnapshot ?? {})) {
    map.set(id, {
      status: snap.status ?? "idle",
      state: snap.state ?? null,
      startedAt: snap.started_at ?? null,
      log: [],
    });
  }

  function ensure(id) {
    if (!map.has(id)) map.set(id, blank());
    return map.get(id);
  }

  function push(id, entry) {
    const rec = ensure(id);
    const nextLog = [...rec.log, entry];
    if (nextLog.length > MAX_LOG) nextLog.splice(0, nextLog.length - MAX_LOG);
    map.set(id, { ...rec, log: nextLog });
  }

  function get(id) {
    return map.get(id) ?? blank();
  }

  function apply(event) {
    const { flow_id: id, kind, payload, at } = event;
    const rec = ensure(id);
    let next = { ...rec };

    if (kind === "started") {
      next = {
        status: "running",
        state: payload.state ?? rec.state,
        startedAt: payload.started_at ?? at,
        log: rec.log,
      };
    } else if (kind === "state") {
      next = { ...next, status: "running", state: payload.state };
    } else if (kind === "done") {
      next = { ...next, status: "done", state: payload.state };
    } else if (kind === "error") {
      next = { ...next, status: "error" };
    } else if (kind === "terminated") {
      next = { ...next, status: rec.status === "done" ? "done" : "stopped" };
    }

    const logEntry = {
      id: `${id}-${at}-${rec.log.length}`,
      at,
      kind,
      summary: summarize(kind, payload),
    };

    const nextLog = [...rec.log, logEntry];
    if (nextLog.length > MAX_LOG) nextLog.splice(0, nextLog.length - MAX_LOG);

    map.set(id, { ...next, log: nextLog });
  }

  function summarize(kind, payload) {
    if (kind === "state" && payload?.state?.__step) return `→ ${payload.state.__step}`;
    if (kind === "error") return payload?.reason ?? "error";
    if (kind === "terminated") return payload?.reason ?? "exit";
    if (kind === "started") return "runner spawned";
    if (kind === "done") return "flow complete";
    return kind;
  }

  return { map, get, apply, push };
}
