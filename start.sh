#!/bin/bash
set -e

: "${GH_TOKEN:?Set GH_TOKEN to a GitHub personal access token}"

docker run -it \
  -e ANTHROPIC_API_KEY=$(jq -r '.primaryApiKey' ~/.claude.json) \
  -e GH_TOKEN="$GH_TOKEN" \
  -v $(pwd):/workspace \
  -v ~/.config/git:/home/node/.config/git:ro \
  -v ~/Projects:/home/node/Projects \
  --network host \
  claude-container
