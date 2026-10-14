# syntax=docker/dockerfile:1.7
# bats + jq + yq + shellcheck + git + openssl + sops + age.
# Образ bats/bats идёт без этих утилит; CI-джобы проекта neinache ставили их при каждом запуске
# (`apk add`), что на загруженных раннерах периодически упиралось в лимит времени джобы.
# Тот же набор, что в .tests/Containerfile проекта neinache.
# ENTRYPOINT и CMD базового образа не меняются: джобы GitLab CI переопределяют entrypoint сами.

ARG BATS_BASE=docker.io/bats/bats:1.14.0@sha256:5322b877351fda0cc435de8c6116de7d0a2ec79d7c680132a0ef329a633bc66f

FROM ${BATS_BASE}

RUN apk add --no-cache jq yq-go shellcheck git openssl sops age
