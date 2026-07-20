# Next Steps

Current branch: codex/full-isometric-game

1. Run the final usability/static review and full suite.
2. Re-export Linux and Windows after any final fixes.
3. Push the final feature branch commit.
4. Safely merge to main, push main, and create annotated v0.9.0.
5. Perform an external native Windows runtime check before promoting beyond pre-release.

Exact resume command:

    cd /home/epi13/Documents/Projects/IsoCastle && PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

Git branch pushes are functional. GitHub CLI still lacks a separate authenticated session, so no connector-created draft PR is required for the owner-authorized direct merge workflow.
