# syntax=docker/dockerfile:1.7
# bats + jq + yq + shellcheck + git + openssl + sops + age + pre-commit.
# The bats/bats image ships without these utilities; the neinache CI jobs used to install them
# on every run (`apk add`, `apt-get`, `pip install`), which on loaded runners periodically hit the job time limit.
# Same set as .tests/Containerfile in the neinache project, plus pre-commit for its pre-commit:hygiene job.
# ENTRYPOINT and CMD of the base image are left untouched: GitLab CI jobs override the entrypoint themselves.

ARG BATS_BASE=docker.io/bats/bats:1.14.0@sha256:5322b877351fda0cc435de8c6116de7d0a2ec79d7c680132a0ef329a633bc66f

FROM ${BATS_BASE}

# Pinned like the base: a new pre-commit release can add behaviour that reddens a pipeline with no repository change.
# Verified against PyPI 2026-10-15.
ARG PRE_COMMIT_VERSION=4.7.0

RUN apk add --no-cache jq yq-go shellcheck git openssl sops age python3

# pre-commit lives in its own virtualenv, so it does not touch the system Python.
# The hook environment is built at image build time into PRE_COMMIT_HOME (absolute, the same in every
# container), so a job runs the hooks without cloning hook repositories or installing hook dependencies.
# pre-commit-hooks.bake.yaml must list every non-local repository of the consumer's .pre-commit-config.yaml with
# the same rev (pre-commit clones all of them to read the manifests, even for a single hook id); the list is
# also written to ${PRE_COMMIT_HOME}/BAKED so the consumer can compare. If the consumer moves to another rev,
# that repository is simply fetched again at run time until this image is rebuilt with the new rev.
ENV VIRTUAL_ENV=/opt/pre-commit-venv \
    PRE_COMMIT_HOME=/opt/pre-commit-home \
    PATH=/opt/pre-commit-venv/bin:${PATH}
COPY pre-commit-hooks.bake.yaml /tmp/bake/.pre-commit-config.yaml
RUN python3 -m venv "${VIRTUAL_ENV}" \
    && "${VIRTUAL_ENV}/bin/python" -m pip install --no-cache-dir "pre-commit==${PRE_COMMIT_VERSION}" \
    && cd /tmp/bake \
    && git init -q \
    && pre-commit install-hooks \
    && yq '.repos[] | .repo + "@" + .rev' .pre-commit-config.yaml | sort > "${PRE_COMMIT_HOME}/BAKED" \
    && cd / \
    && rm -rf /tmp/bake
