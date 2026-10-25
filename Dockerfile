# syntax=docker/dockerfile:1.7
# neinache CI toolchain.
#
# Debian, not Alpine: the mise builds (GraalVM, CPython, Node, Go) are glibc
# binaries and do not run on the bats/bats (Alpine) base this image used to
# have. Jobs that used to `mise install` at start now find the binaries already
# on PATH. /opt/neinache/bin is ahead of the mise shims, so a shim cannot
# refetch a tool that is already baked.
#
# jq, git and openssl stay outside mise. git ships in the mise base image.
# pre-commit and its hook repositories are still baked, same as before.

ARG MISE_IMAGE=docker.io/jdxcode/mise:2026.10.15-debian@sha256:329c5517b4ce4e63cfbe619b4d49b4a4ffefa546d7c1d99d59f54043c38191bf

FROM ${MISE_IMAGE}

# Pinned like the base: a new pre-commit release can add behaviour that reddens a pipeline with no repository change.
# Verified against PyPI 2026-10-15.
ARG PRE_COMMIT_VERSION=4.7.0

# jq has no mise pin in neinache. openssl is the one tls-store tests call.
# Versions follow Debian 13 at the moment of the build; the base image digest
# is what a rebuild moves when those packages must change.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/neinache
COPY mise.toml .

# `mise which` resolves against this directory's mise.toml. The symlinks point
# at the real binaries, not at shims. podman-remote is linked as `podman`
# because Quarkus reads argv[0] and only accepts a line that starts with
# "podman version". JAVA_HOME is a stable symlink so the ENV below does not
# hardcode the install directory mise chooses.
RUN set -eu \
    && mise trust /opt/neinache/mise.toml \
    && mise install -y \
    && mkdir -p /opt/neinache/bin \
    && link() { ln -sfn "$(mise which "$1")" "/opt/neinache/bin/${2:-$1}"; } \
    && link java \
    && link python \
    && link python python3 \
    && link node \
    && link pnpm \
    && link kubectl \
    && link yq \
    && link helm \
    && link kustomize \
    && link argocd \
    && link sops \
    && link age \
    && link lychee \
    && link terraform \
    && link tflint \
    && link trivy \
    && link go \
    && link bats \
    && link shellcheck \
    && link podman-remote podman \
    && link podman-remote podman-remote \
    && ln -sfn "$(mise where java)" /opt/neinache/java-home

ENV JAVA_HOME=/opt/neinache/java-home \
    PATH="/opt/neinache/bin:/opt/neinache/java-home/bin:${PATH}"

# pre-commit lives in its own virtualenv, so it does not touch the mise Python
# beyond being built by it. The hook environment is built at image build time
# into PRE_COMMIT_HOME (absolute, the same in every container), so a job runs
# the hooks without cloning hook repositories or installing hook dependencies.
# pre-commit-hooks.bake.yaml must list every non-local repository of the
# consumer's .pre-commit-config.yaml with the same rev (pre-commit clones all
# of them to read the manifests, even for a single hook id); the list is also
# written to ${PRE_COMMIT_HOME}/BAKED so the consumer can compare. If the
# consumer moves to another rev, that repository is simply fetched again at
# run time until this image is rebuilt with the new rev.
ENV VIRTUAL_ENV=/opt/pre-commit-venv \
    PRE_COMMIT_HOME=/opt/pre-commit-home
COPY pre-commit-hooks.bake.yaml /tmp/bake/.pre-commit-config.yaml
RUN set -eu \
    && python3 -m venv "${VIRTUAL_ENV}" \
    && "${VIRTUAL_ENV}/bin/python" -m pip install --no-cache-dir "pre-commit==${PRE_COMMIT_VERSION}" \
    && cd /tmp/bake \
    && git init -q \
    && "${VIRTUAL_ENV}/bin/pre-commit" install-hooks \
    && yq '.repos[] | .repo + "@" + .rev' .pre-commit-config.yaml | sort > "${PRE_COMMIT_HOME}/BAKED" \
    && cd / \
    && rm -rf /tmp/bake

# venv bin first so `pre-commit` resolves to the baked one. The mise tool bins
# stay ahead of the shims.
ENV PATH="/opt/pre-commit-venv/bin:${PATH}"

WORKDIR /
