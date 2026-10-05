FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Project SDKs are intentionally not pinned yet.
# Add mobile/backend toolchains here after the architecture decision is accepted.
# Do not require project SDK installation on the Mac host.

RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl jq ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
