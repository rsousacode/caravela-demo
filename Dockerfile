# syntax=docker/dockerfile:1.7
#
# Multi-stage build: Elixir + Node assets -> Mix release -> slim Debian runtime.
#
# Bump these to match your dev toolchain. Tags come from https://hub.docker.com/r/hexpm/elixir
ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28.1.2
ARG DEBIAN_VERSION=bookworm-20251001-slim
ARG NODE_VERSION=22

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ---- Stage 1: build ---------------------------------------------------------
FROM ${BUILDER_IMAGE} AS builder

ARG NODE_VERSION
ENV LANG=C.UTF-8 MIX_ENV=prod

RUN apt-get update -y \
 && apt-get install -y --no-install-recommends build-essential git ca-certificates curl \
 && curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

# Deps first so the layer caches when only app code changes.
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod \
 && mix deps.compile

# Assets: Phoenix + LiveSvelte pull JS packages from the compiled deps, so
# install after deps are in place.
COPY assets assets
RUN cd assets && npm ci --no-audit --no-fund --prefer-offline

# App source
COPY priv priv
COPY lib lib

# Build assets (vite) then the release.
RUN mix assets.deploy \
 && mix compile

COPY rel rel
RUN mix release

# ---- Stage 2: runtime -------------------------------------------------------
FROM ${RUNNER_IMAGE} AS runner

RUN apt-get update -y \
 && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 locales ca-certificates tini \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 \
    MIX_ENV=prod PHX_SERVER=true PORT=4000

WORKDIR /app
RUN useradd --create-home --shell /bin/bash app \
 && chown -R app:app /app
USER app

COPY --from=builder --chown=app:app /app/_build/prod/rel/caravela_demo ./

EXPOSE 4000

# tini reaps zombies; the release entrypoint uses `exec` internally.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/bin/server"]
