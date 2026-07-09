#!/bin/bash
set -e

docker run -it \
  -e GH_TOKEN="$(gh auth token)" \
  -e CORALOGIX_API_KEY="$(jq -r '.mcpServers.coralogix.headers.Authorization | sub("^Bearer "; "")' ~/.claude.json)" \
  -v ~/.claude/.credentials.json:/home/node/.claude/.credentials.json:ro \
  -v ~/.claude/remote-settings.json:/home/node/.claude/remote-settings.json:ro \
  -v ~/.claude/statusline.sh:/home/node/.claude/statusline.sh:ro \
  -v $(pwd):/workspace \
  -v ~/.config/git:/home/node/.config/git:ro \
  -v ~/.ssh:/home/tperlaki/.ssh:ro \
  -v ~/Projects:/home/node/Projects \
  -v /run/user/$(id -u)/bus:/run/user/1000/bus \
  -e DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" \
  --network host \
  claude-container

