// Ensure Tailwind's content scanner sees every dynamically interpolated class.
// This file is never imported at runtime — the string literals alone are enough.
export const _safelist = `
  bg-wave-300 bg-wave-400 bg-wave-500 bg-wave-600
  bg-sail bg-ember bg-reef bg-sand bg-coral
  text-wave-300 text-wave-400 text-wave-500 text-wave-600
  text-sail text-ember text-reef text-sand text-coral
  border-wave-300 border-wave-400 border-wave-500 border-wave-600
  border-sail border-ember border-reef border-sand border-coral
  border-wave-300/40 border-wave-400/40 border-wave-500/40 border-wave-600/40
  border-sail/40 border-ember/40 border-reef/40 border-sand/40 border-coral/40
  border-wave-300/50 border-wave-400/50 border-wave-500/50 border-wave-600/50
  border-sail/50 border-ember/50 border-reef/50 border-sand/50 border-coral/50
  hover:border-wave-300/40 hover:border-wave-400/40 hover:border-wave-500/40 hover:border-wave-600/40
  hover:border-sail/40 hover:border-ember/40 hover:border-reef/40 hover:border-sand/40 hover:border-coral/40
  hover:border-wave-300/50 hover:border-wave-400/50 hover:border-wave-500/50 hover:border-wave-600/50
  hover:border-sail/50 hover:border-ember/50 hover:border-reef/50 hover:border-sand/50 hover:border-coral/50
`;
