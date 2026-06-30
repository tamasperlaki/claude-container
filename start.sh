#!/bin/bash
set -e

GH_TOKEN="$(gh auth token)"

docker run -it \
  -e GH_TOKEN="$GH_TOKEN" \
  -v ~/.claude/.credentials.json:/home/node/.claude/.credentials.json:ro \
  -v $(pwd):/workspace \
  -v ~/.config/git:/home/node/.config/git:ro \
  -v ~/Projects:/home/node/Projects \
  --network host \
  claude-container
