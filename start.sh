#!/bin/bash
set -e

docker run -it \
  -e GH_TOKEN="$(gh auth token)" \
  -v ~/.claude/.credentials.json:/home/node/.claude/.credentials.json:ro \
  -v ~/.claude/remote-settings.json:/home/node/.claude/remote-settings.json:ro \
  -v ~/.claude/statusline.sh:/home/node/.claude/statusline.sh:ro \
  -v $(pwd):/workspace \
  -v ~/.config/git:/home/node/.config/git:ro \
  -v ~/.ssh:/home/tperlaki/.ssh:ro \
  -v ~/Projects:/home/node/Projects \
  --network host \
  claude-container
