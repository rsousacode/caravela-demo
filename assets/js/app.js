import "../css/app.css";

import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { getHooks } from "live_svelte";
import Components from "../svelte/index.js";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { ...getHooks(Components) },
});

liveSocket.connect();
window.liveSocket = liveSocket;
