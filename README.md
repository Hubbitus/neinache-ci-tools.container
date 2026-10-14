# neinache-ci-tools

Tools image for the neinache CI. It is [bats](https://github.com/bats-core/bats-core) with the utilities that tests and checks need: `jq`, `yq` (Alpine package `yq-go`), `shellcheck`, `git`, `openssl`, `sops` and `age`.

Published as [`docker.io/hubbitus/neinache-ci-tools`](https://hub.docker.com/r/hubbitus/neinache-ci-tools).

## Why

CI jobs used to install these packages on every run (`apk add`). On a loaded runner the download periodically stalled until the job time limit. The image is built once, and jobs only pull it (and the runner caches it).

## Contents

| What           | Source                                                                                                     |
|----------------|------------------------------------------------------------------------------------------------------------|
| Base           | `docker.io/bats/bats:1.14.0`, pinned by digest (Alpine)                                                    |
| Utilities      | `apk add --no-cache jq yq-go shellcheck git openssl sops age`, versions come from the base's Alpine branch |
| ENTRYPOINT/CMD | unchanged from the base image (`/tini -- bash bats`); in GitLab CI set `entrypoint: [""]`                  |

Exact tool versions are printed by the `Print tool versions` step of the latest build (`.github/workflows/build.yml`).

## Tags

- `1.14.0-YYYYMMDD`: bats version and build date, published on every push to `main`;
- `<short sha>`: the commit that was built.

Consumers should pin the image by digest: `docker.io/hubbitus/neinache-ci-tools:1.14.0-YYYYMMDD@sha256:...`.

## Usage in GitLab CI

```yaml
image:
  name: docker.io/hubbitus/neinache-ci-tools:1.14.0-YYYYMMDD@sha256:...
  entrypoint: [""]
```

## Build locally

```bash
podman build -t neinache-ci-tools:local .
podman run --rm --entrypoint '' neinache-ci-tools:local sh -c 'jq --version && yq --version && shellcheck --version && git --version && openssl version && sops --version && age --version && bats --version'
```

## Secrets

The publish workflow expects Docker Hub credentials in the repository settings:

- `DOCKERHUB_USER`: repository **variable** (the user name is not a secret);
- `DOCKERHUB_TOKEN`: repository **secret**.

They are not stored in this repository.
