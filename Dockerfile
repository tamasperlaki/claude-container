FROM node:20

USER node

RUN curl -fsSL https://claude.ai/install.sh | bash

WORKDIR /workspace

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]

