# neinache-ci-tools

Tools image for the neinache CI. It is [bats](https://github.com/bats-core/bats-core) with the utilities that tests and checks need: `jq`, `yq` (Alpine package `yq-go`), `shellcheck`, `git`, `openssl`, `sops` and `age`, plus Python and [pre-commit](https://pre-commit.com) with a prebuilt hook environment.

Published as [`docker.io/hubbitus/neinache-ci-tools`](https://hub.docker.com/r/hubbitus/neinache-ci-tools).

## Why

CI jobs used to install these packages on every run (`apk add`, `apt-get`, `pip install`, cloning hook repositories). On a loaded runner the downloads periodically stalled until the job time limit. The image is built once, and jobs only pull it (and the runner caches it).

## Contents

| What           | Source                                                                                                                                                                                                                                                         |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Base           | `docker.io/bats/bats:1.14.0`, pinned by digest (Alpine)                                                                                                                                                                                                        |
| Utilities      | `apk add --no-cache jq yq-go shellcheck git openssl sops age python3`, versions come from the base's Alpine branch                                                                                                                                             |
| pre-commit     | `pre-commit==4.7.0` in its own virtualenv (`/opt/pre-commit-venv`), pinned in the `Dockerfile`                                                                                                                                                                 |
| Hook env       | `pre-commit install-hooks` at build time into `PRE_COMMIT_HOME=/opt/pre-commit-home`, from `pre-commit-hooks.bake.yaml` (`pre-commit-hooks` v6.0.0 with `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`; `pre-commit-terraform` v1.109.2, clone only) |
| ENTRYPOINT/CMD | unchanged from the base image (`/tini -- bash bats`); in GitLab CI set `entrypoint: [""]`                                                                                                                                                                      |

Exact tool versions are printed by the `Print tool versions` step of the latest build (`.github/workflows/build.yml`).

## Tags

- `1.14.0-YYYYMMDDHHmm`: bats version and build time (UTC), published on every push to `main`. Older tags `1.14.0-YYYYMMDD` stay valid; the longer number always sorts later, which is what a versioning rule on `-<number>` needs;
- `<short sha>`: the commit that was built.

Consumers should pin the image by digest: `docker.io/hubbitus/neinache-ci-tools:1.14.0-YYYYMMDDHHmm@sha256:...`.

## Usage in GitLab CI

```yaml
image:
  name: docker.io/hubbitus/neinache-ci-tools:1.14.0-YYYYMMDDHHmm@sha256:...
  entrypoint: [""]
```

## Build locally

```bash
podman build -t neinache-ci-tools:local .
podman run --rm --entrypoint '' neinache-ci-tools:local sh -c 'jq --version && yq --version && shellcheck --version && git --version && openssl version && sops --version && age --version && bats --version'
```

## Pre-commit hook environment

`pre-commit-hooks.bake.yaml` must list every non-local repository of the consumer's `.pre-commit-config.yaml` with the same `rev`: pre-commit clones all of them to read the hook manifests even when it runs a single hook id. The list is also written to `/opt/pre-commit-home/BAKED` (one `repo@rev` per line) so a consumer can compare it with its own config. If the consumer moves to another `rev`, pre-commit simply fetches that repository again at run time (network, as before) until this image is rebuilt with the new `rev`. `test/pre-commit-offline.sh` runs in the smoke job with `--network none` and proves the baked environment is enough: clean files pass, real violations fail.

The baked `PRE_COMMIT_HOME` belongs to root (directories 0700, `db.db` 0600): the GitLab runner runs jobs as root, which works. As another user, pre-commit fails with `unable to open database file`; point `PRE_COMMIT_HOME` at a writable copy of it instead.

## Updating the image

Manual: rebuild and publish with `workflow_dispatch` (or push to `main`) when the `bats/bats` digest, a tool, `PRE_COMMIT_VERSION` or the hook `rev` has to move, then bump the pin in the consumer. There is no scheduled rebuild on purpose: every rebuild is a new tag and a new merge request in the consumer.

## Secrets

The publish workflow expects Docker Hub credentials in the repository settings:

- `DOCKERHUB_USER`: repository **variable** (the user name is not a secret);
- `DOCKERHUB_TOKEN`: repository **secret**.

They are not stored in this repository.
