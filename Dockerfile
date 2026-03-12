FROM node:20

RUN curl -fL https://claude.ai/install.sh | bash

WORKDIR /workspace

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]

