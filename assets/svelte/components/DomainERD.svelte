<script>
  let { entities = [], relations = [] } = $props();

  const BOX_W = 180;
  const BOX_HEADER = 40;
  const ROW_H = 22;
  const BOX_PAD_Y = 16;
  const GAP_X = 88;
  const MARGIN = 24;

  const ACCENTS = ["wave-400", "sail", "reef", "ember", "sand"];

  const layout = $derived.by(() => {
    const boxes = entities.map((e, i) => {
      const h = BOX_HEADER + e.fields.length * ROW_H + BOX_PAD_Y;
      return {
        entity: e,
        x: MARGIN + i * (BOX_W + GAP_X),
        y: MARGIN + 40,
        w: BOX_W,
        h,
        accent: ACCENTS[i % ACCENTS.length],
      };
    });

    const byName = Object.fromEntries(boxes.map((b) => [b.entity.name, b]));

    const edges = relations
      .map((r) => {
        const a = byName[r.from];
        const b = byName[r.to];
        if (!a || !b) return null;
        const left = a.x < b.x ? a : b;
        const right = a.x < b.x ? b : a;
        const x1 = left.x + left.w;
        const x2 = right.x;
        const y1 = left.y + left.h / 2;
        const y2 = right.y + right.h / 2;
        const midX = (x1 + x2) / 2;
        const d = `M ${x1} ${y1} C ${midX} ${y1}, ${midX} ${y2}, ${x2} ${y2}`;
        return {
          d,
          label: r.type,
          labelX: midX,
          labelY: (y1 + y2) / 2 - 6,
          reversed: a.x >= b.x,
        };
      })
      .filter(Boolean);

    const maxX = boxes.reduce((m, b) => Math.max(m, b.x + b.w), 0) + MARGIN;
    const maxY = boxes.reduce((m, b) => Math.max(m, b.y + b.h), 0) + MARGIN;

    return { boxes, edges, width: maxX, height: maxY };
  });
</script>

<div class="rounded-xl border border-ink-700/80 bg-ink-900/60 overflow-auto">
  <div class="px-4 py-2.5 border-b border-ink-700/60 flex items-center justify-between">
    <span class="text-xs text-ink-400 uppercase tracking-widest">
      Entity · relation graph
    </span>
    <span class="text-[11px] text-ink-500">
      {entities.length} entities · {relations.length} relations
    </span>
  </div>

  <div class="p-4">
    <svg
      viewBox="0 0 {layout.width} {layout.height}"
      class="w-full h-auto"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <marker
          id="arrow"
          viewBox="0 0 10 10"
          refX="9"
          refY="5"
          markerWidth="6"
          markerHeight="6"
          orient="auto-start-reverse"
        >
          <path d="M 0 0 L 10 5 L 0 10 z" fill="#475569" />
        </marker>
      </defs>

      {#each layout.edges as edge}
        <path
          d={edge.d}
          fill="none"
          stroke="#475569"
          stroke-width="1.5"
          stroke-dasharray="4 3"
          marker-end="url(#arrow)"
        />
        <g transform="translate({edge.labelX}, {edge.labelY})">
          <rect
            x="-36"
            y="-10"
            width="72"
            height="18"
            rx="9"
            fill="#0f172a"
            stroke="#334155"
          />
          <text
            text-anchor="middle"
            y="3"
            class="text-[10px] fill-ink-300 font-mono"
            style="font-size: 10px;"
          >
            {edge.label}
          </text>
        </g>
      {/each}

      {#each layout.boxes as box}
        <g transform="translate({box.x}, {box.y})">
          <rect
            width={box.w}
            height={box.h}
            rx="10"
            fill="#020617"
            stroke="currentColor"
            stroke-width="1"
            class="text-{box.accent}"
            opacity="0.85"
          />
          <rect
            width={box.w}
            height={BOX_HEADER}
            rx="10"
            fill="currentColor"
            class="text-{box.accent}"
            opacity="0.15"
          />
          <text
            x="14"
            y="25"
            class="fill-ink-50 font-semibold"
            style="font-size: 13px;"
          >
            {box.entity.name}
          </text>
          <text
            x={box.w - 14}
            y="25"
            text-anchor="end"
            class="fill-ink-500"
            style="font-size: 10px;"
          >
            {box.entity.field_count}F
          </text>

          {#each box.entity.fields as field, idx}
            <g transform="translate(14, {BOX_HEADER + 14 + idx * ROW_H})">
              <text class="fill-ink-200" style="font-size: 11px;">
                {field.name}
              </text>
              <text
                x={box.w - 28}
                text-anchor="end"
                class="fill-ink-500"
                style="font-size: 10px;"
              >
                :{field.type}
              </text>
              {#if field.required}
                <circle cx={box.w - 20} cy="-3" r="3" fill="#fb923c" />
              {/if}
            </g>
          {/each}
        </g>
      {/each}
    </svg>
  </div>
</div>
