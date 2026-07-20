# Next Steps

Release state: `main` contains merged PR #1 and the unchanged `v0.9.0` pre-release record. The inventory, input-remapping, and supported WebAssembly milestone is on `codex/post-v0.9-inventory-input-wasm`, based on `52bfc323949a762703a7057ef38cc044fbf38e1b`. See `git log` for the final milestone commit after publication.

1. Perform a native Windows runtime check before promoting beyond pre-release.
2. Review the feature pull request and its CI Web artifact; do not merge automatically.
3. Exercise physical-controller remapping and gamepad navigation on representative desktop hardware; automated serialization/controller-event coverage passes, but no physical controller was connected during this run.
4. Exercise optional fullscreen enter/leave and mobile-browser layout on representative hardware; desktop headless Chromium and Firefox coverage passes.
5. Expand the generic spell resolver into bespoke line, cone, chain, summon, aura, and ground-target selection UX.
6. Continue hand-authored surface-area and encounter presentation polish for a future 1.0 candidate.

Exact resume command:

    cd /home/epi13/Documents/Projects/IsoCastle && git status --short --branch && gh pr checks --watch

If CI has already finished, inspect its Web artifact and begin the externally blocked Windows test or the next gameplay milestone. Git HTTPS publication and GitHub CLI authentication were both verified during recovery.
