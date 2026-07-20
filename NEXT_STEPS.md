# Next Steps

Release state: `main` contains merged PR #1 and the unchanged `v0.9.0` pre-release record. Post-release work is active on `codex/post-v0.9-inventory-input-wasm` from commit `52bfc323949a762703a7057ef38cc044fbf38e1b`.

1. Perform a native Windows runtime check before promoting beyond pre-release.
2. Complete the in-progress literal mouse drag-and-drop inventory interactions, full in-game input-remapping editor, and supported single-threaded WebAssembly export/browser test workflow.
3. Expand the generic spell resolver into bespoke line, cone, chain, summon, aura, and ground-target selection UX.
4. Continue hand-authored surface-area and encounter presentation polish for a future 1.0 candidate.

Exact resume command:

    cd /home/epi13/Documents/Projects/IsoCastle && git status --short --branch && PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

Git HTTPS publication and GitHub CLI authentication were both verified during recovery.
