# syntax=docker/dockerfile:1.7
# bats + jq + yq + shellcheck + git + openssl + sops + age.
# The bats/bats image ships without these utilities; the neinache CI jobs used to install them
# on every run (`apk add`), which on loaded runners periodically hit the job time limit.
# Same set as .tests/Containerfile in the neinache project.
# ENTRYPOINT and CMD of the base image are left untouched: GitLab CI jobs override the entrypoint themselves.

ARG BATS_BASE=docker.io/bats/bats:1.14.0@sha256:5322b877351fda0cc435de8c6116de7d0a2ec79d7c680132a0ef329a633bc66f

FROM ${BATS_BASE}

RUN apk add --no-cache jq yq-go shellcheck git openssl sops age
