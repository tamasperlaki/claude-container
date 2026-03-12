FROM node:20-bookworm

# Install tools: git, gh, jq, maven, java (matching your local stack)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    jq \
    maven \
    default-jdk \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Set up non-root user
USER node

# Install Claude Code (native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Bake in Claude config
COPY --chown=node:node config/.claude.json /home/node/.claude.json
COPY --chown=node:node config/settings.json /home/node/.claude/settings.json
COPY --chown=node:node config/CLAUDE.md /home/node/.claude/CLAUDE.md

WORKDIR /workspace

ENTRYPOINT ["/home/node/.local/bin/claude"]
CMD ["--dangerously-skip-permissions"]
