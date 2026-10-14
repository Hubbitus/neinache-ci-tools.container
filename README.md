# neinache-ci-tools

Образ утилит для CI проекта neinache (внутри bats, поэтому тесты и проверки идут в нём же).

[bats](https://github.com/bats-core/bats-core) с набором утилит, которые нужны тестам и проверкам CI:
`jq`, `yq` (пакет `yq-go`), `shellcheck`, `git`, `openssl`, `sops`, `age`.

Опубликован: [`docker.io/hubbitus/neinache-ci-tools`](https://hub.docker.com/r/hubbitus/neinache-ci-tools).

Зачем: чтобы CI-джобы не ставили эти пакеты при каждом запуске. Установка из сети на загруженном раннере
периодически зависала до лимита времени джобы.

## Состав

| Что            | Откуда                                                                                                  |
|----------------|---------------------------------------------------------------------------------------------------------|
| База           | `docker.io/bats/bats:1.14.0`, закреплена по digest (Alpine)                                             |
| Утилиты        | `apk add --no-cache jq yq-go shellcheck git openssl sops age` — версии берутся из Alpine-ветки базы     |
| ENTRYPOINT/CMD | как у базового образа (`/tini -- bash bats`); в GitLab CI задаётся `entrypoint: [""]`                    |

Точные версии утилит смотрите в логе шага `Print tool versions` последней сборки (`.github/workflows/build.yml`).

## Теги

- `1.14.0-YYYYMMDD` — версия bats и дата сборки (публикуется при каждом push в `main`);
- `<короткий sha>` — коммит сборки.

В потребителях образ нужно закреплять по digest: `image: docker.io/hubbitus/neinache-ci-tools:1.14.0-YYYYMMDD@sha256:...`.

## Использование в GitLab CI

```yaml
image:
  name: docker.io/hubbitus/neinache-ci-tools:1.14.0-YYYYMMDD@sha256:...
  entrypoint: [""]
```

## Сборка локально

```bash
podman build -t neinache-ci-tools:local .
podman run --rm --entrypoint '' neinache-ci-tools:local sh -c 'jq --version && yq --version && shellcheck --version && git --version && openssl version && sops --version && age --version && bats --version'
```

## Секреты

Workflow публикации ожидает в секретах репозитория учётные данные Docker Hub:

- `DOCKERHUB_USER`
- `DOCKERHUB_TOKEN`

В репозитории они не хранятся.
