// Minimal line-level LCS-based diff for the generators panel.
// Returns an array of { kind: "equal"|"add"|"remove", line, oldNo, newNo }.
export function diffLines(a = "", b = "") {
  const aLines = a.split("\n");
  const bLines = b.split("\n");
  const n = aLines.length;
  const m = bLines.length;

  const dp = Array.from({ length: n + 1 }, () => new Uint32Array(m + 1));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      dp[i][j] = aLines[i] === bLines[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }

  const out = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (aLines[i] === bLines[j]) {
      out.push({ kind: "equal", line: aLines[i], oldNo: i + 1, newNo: j + 1 });
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      out.push({ kind: "remove", line: aLines[i], oldNo: i + 1, newNo: null });
      i++;
    } else {
      out.push({ kind: "add", line: bLines[j], oldNo: null, newNo: j + 1 });
      j++;
    }
  }
  while (i < n) {
    out.push({ kind: "remove", line: aLines[i], oldNo: i + 1, newNo: null });
    i++;
  }
  while (j < m) {
    out.push({ kind: "add", line: bLines[j], oldNo: null, newNo: j + 1 });
    j++;
  }
  return out;
}
