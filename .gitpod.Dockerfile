FROM gitpod/workspace-full

# Install GitHub CLI
RUN brew install gh

# Install Docker for local development
RUN brew install docker
