# neinache-ci-tools

Tools image for the neinache CI. Debian image with every tool from neinache's `mise.toml` `[tools]` table already installed, plus `jq`, `git`, `openssl` and [pre-commit](https://pre-commit.com) with a prebuilt hook environment. Jobs do not download the toolchain at start.

Published as [`docker.io/hubbitus/neinache-ci-tools`](https://hub.docker.com/r/hubbitus/neinache-ci-tools).

## Why

CI jobs used to install packages and the mise toolchain on every run (`apk add`, `apt-get`, `pip install`, `mise install`, cloning hook repositories). On a loaded runner the downloads periodically stalled until the job time limit. The image is built once, and jobs only pull it (and the runner caches it). A pin in `mise.toml` stays stale here until the image is rebuilt.

## Contents

| What           | Source                                                                                                                                                                                                                                                         |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Base           | `docker.io/jdxcode/mise:2026.10.15-debian`, pinned by digest (Debian 13, glibc). Alpine cannot run the glibc tool builds                                                                       |
| Mise tools     | `mise install` of `mise.toml` at build time: java (GraalVM CE 25.0.2), python 3.15.0, node 24.21.0, pnpm 12.11.2, kubectl, yq, helm, kustomize, argocd, sops, age, lychee, podman 6.1.4, terraform 1.16.6, tflint, trivy, go 1.27.2, bats 1.14.0, shellcheck 0.11.0. Symlinked into `/opt/neinache/bin`, which is ahead of the mise shims. `JAVA_HOME=/opt/neinache/java-home`. `podman` is `podman-remote` under that name so Quarkus sees `podman version` |
| Utilities      | `apt-get install jq openssl ca-certificates`. `git` comes with the mise base image                                                                                                                                                                              |
| pre-commit     | `pre-commit==4.7.0` in its own virtualenv (`/opt/pre-commit-venv`), pinned in the `Dockerfile`                                                                                                                                                                 |
| Hook env       | `pre-commit install-hooks` at build time into `PRE_COMMIT_HOME=/opt/pre-commit-home`, from `pre-commit-hooks.bake.yaml` (`pre-commit-hooks` v6.0.0 with `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`; `pre-commit-terraform` v1.109.2, clone only) |
| ENTRYPOINT/CMD | the mise base image sets none; in GitLab CI set `entrypoint: [""]`                                                                                                                                                                                             |

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
podman run --rm --network none --entrypoint '' -v "$PWD:/repo:ro" neinache-ci-tools:local /repo/test/tools-offline.sh
```

## Pre-commit hook environment

`pre-commit-hooks.bake.yaml` must list every non-local repository of the consumer's `.pre-commit-config.yaml` with the same `rev`: pre-commit clones all of them to read the hook manifests even when it runs a single hook id. The list is also written to `/opt/pre-commit-home/BAKED` (one `repo@rev` per line) so a consumer can compare it with its own config. If the consumer moves to another `rev`, pre-commit simply fetches that repository again at run time (network, as before) until this image is rebuilt with the new `rev`. `test/pre-commit-offline.sh` runs in the smoke job with `--network none` and proves the baked environment is enough: clean files pass, real violations fail.

The baked `PRE_COMMIT_HOME` belongs to root (directories 0700, `db.db` 0600): the GitLab runner runs jobs as root, which works. As another user, pre-commit fails with `unable to open database file`; point `PRE_COMMIT_HOME` at a writable copy of it instead.

## Updating the image

Manual: rebuild and publish with `workflow_dispatch` (or push to `main`) when the mise base digest, a pin in `mise.toml`, `PRE_COMMIT_VERSION` or a hook `rev` has to move, then bump the pin in the consumer. There is no scheduled rebuild on purpose: every rebuild is a new tag and a new merge request in the consumer. The tag prefix stays `1.14.0-` (the bats version this image installs) so the consumer's versioning rule keeps sorting newer builds later.

## Secrets

The publish workflow expects Docker Hub credentials in the repository settings:

- `DOCKERHUB_USER`: repository **variable** (the user name is not a secret);
- `DOCKERHUB_TOKEN`: repository **secret**.

They are not stored in this repository.
