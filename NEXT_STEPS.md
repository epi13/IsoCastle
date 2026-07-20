# Next Steps

Release state: `main` contains merged PR #1 and the `v0.9.0` pre-release record.

1. Perform a native Windows runtime check before promoting beyond pre-release.
2. Add literal mouse drag-and-drop inventory interactions and a full in-game input-remapping editor.
3. Expand the generic spell resolver into bespoke line, cone, chain, summon, aura, and ground-target selection UX.
4. Continue hand-authored surface-area and encounter presentation polish for a future 1.0 candidate.

Exact resume command:

    cd /home/epi13/Documents/Projects/IsoCastle && PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

Git branch and tag pushes are functional. GitHub CLI still lacks a separate authenticated session; ordinary Git HTTPS publication is working.
