# Next Steps

Current branch: codex/full-isometric-game

1. Complete Milestone 0 files and run the first headless scene.
2. Generate validated content, art, and audio catalogs.
3. Implement the complete playable campaign and automated smoke path.
4. Export Linux, prepare Windows export, update final counts and QA evidence.
5. Authenticate GitHub, push milestones, safely merge to main, and create annotated v0.9.0.

Exact resume command:

    cd /home/epi13/Documents/Projects/IsoCastle && PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

Known external blocker: HTTPS push has no token and gh is not logged in. Before publishing, run gh auth login in a user terminal or provide a working SSH credential; never commit a token.

