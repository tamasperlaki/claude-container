# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo packages **Claude Code itself** into a Docker image (`claude-container`) so it can run in an isolated, sandboxed environment with `--dangerously-skip-permissions` (bypass mode). It is infrastructure/config, not an application — there is no test suite or app code.

## Commands

- **Build the image:** `./build.sh` (runs `docker build --network=host . -t claude-container`)
- **Run the container:** `./start.sh` (runs the `claude-container` image interactively against the current directory)

`--network=host` is required for both build and run in this environment; don't remove it.

## Architecture

Three layers combine to produce a working containerized Claude Code:

1. **`Dockerfile`** — `node:20-bookworm` base with the dev toolchain baked in (git, gh, jq, maven, default-jdk, python3). Installs the GitHub CLI from its apt repo, then Claude Code via the native installer (`curl claude.ai/install.sh`). Runs as the non-root `node` user. `ENTRYPOINT` is `claude`; default `CMD` is `--dangerously-skip-permissions`.

2. **Build-time config (`config/`, `COPY`d into the image)** — this is baked in and changing it requires a rebuild:
   - `config/.claude.json` → `/home/node/.claude.json`: onboarding/trust state so Claude starts without prompts (`hasCompletedOnboarding`, `/workspace` trust accepted, approved API key hash).
   - `config/settings.json` → `/home/node/.claude/settings.json`: bypass permissions mode, model `opus[1m]`, tool search, always-thinking, empty commit/PR attribution, and **plugins** (see below).

3. **Runtime mounts (`start.sh`)** — host state injected at `docker run`, so changing it does *not* need a rebuild:
   - `~/.claude/.credentials.json` (auth), `~/.claude/remote-settings.json` (mounted read-only to skip the managed-settings approval prompt), `~/.claude/statusline.sh` (the script the baked `statusLine` setting invokes — the setting lives in the image, but the script is mounted from the host).
   - `$(pwd)` → `/workspace` (the project Claude operates on), plus `~/Projects` and `~/.config/git`.
   - `GH_TOKEN` is passed via `-e GH_TOKEN="$(gh auth token)"` — sourced live from the host's `gh` login rather than baked in.
   - `CORALOGIX_API_KEY` is passed via `-e`, extracted live from the host's `~/.claude.json` (`mcpServers.coralogix.headers.Authorization`) — same live-sourcing pattern as `GH_TOKEN`, keeps the token out of the image.

## MCP servers

`config/.claude.json` bakes in the `mcpServers` block (server URL/type — no secrets). The `coralogix` server's `Authorization` header uses `${CORALOGIX_API_KEY}` expansion, which requires `httpHookAllowedEnvVars: ["CORALOGIX_API_KEY"]` in `config/settings.json` (Claude Code blocks env expansion in MCP headers unless allowlisted). The actual token is supplied at runtime by `start.sh` (see above) — never hardcode it in `config/`.

**Rule of thumb:** durable defaults (tools, onboarding, settings) live in the image and need `./build.sh`; secrets and per-run state are mounted in `start.sh` and take effect on the next run.

## Plugins

Plugins are configured entirely in `config/settings.json` (baked in — a change requires `./build.sh`). Two keys work together:

- `extraKnownMarketplaces` — registers a git-backed marketplace as pre-trusted (no interactive "add marketplace?" prompt), keyed by marketplace name:
  ```json
  "extraKnownMarketplaces": {
    "meltwater-agents": { "source": { "source": "github", "repo": "meltwater/agents" } }
  }
  ```
- `enabledPlugins` — turns individual plugins on, keyed by `plugin-name@marketplace-name`:
  ```json
  "enabledPlugins": { "coralogix-querying@meltwater-agents": true }
  ```

The marketplace repo is **cloned and cached on first container start** into `~/.claude/plugins/cache/` (not baked into the image). This relies on the container's `--network host` and the `GH_TOKEN` passed by `start.sh` — so **private marketplace repos (e.g. `meltwater/agents`) require that token to have read access to the repo**. Public repos (e.g. `JuliusBrussee/caveman`) work without it.

To add another plugin: add its marketplace to `extraKnownMarketplaces` (if new), add a `name@marketplace: true` entry to `enabledPlugins`, then `./build.sh`.

## Gotchas

- In `start.sh`, `~/.ssh` is mounted to `/home/tperlaki/.ssh`, but the container user is `node` (home `/home/node`). Verify this path matches the intended user before relying on SSH commit signing inside the container.
