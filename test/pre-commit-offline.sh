#!/bin/sh
# Runs inside the image with no network (see the smoke job): the baked hook environment must be enough
# to run the generic pre-commit-hooks the consumer uses. Clean files pass, real violations fail.
set -eu
work=$(mktemp -d)
cd "$work"
git init -q
git config --global --add safe.directory "$work"
cp /repo/pre-commit-hooks.bake.yaml .pre-commit-config.yaml
printf 'a: 1\nb:\n  - x\n' > ok.yaml
git add -A

for hook in trailing-whitespace end-of-file-fixer check-yaml; do
  pre-commit run --all-files "$hook" || { echo "clean tree failed on $hook"; exit 1; }
done

printf 'a: 1  \n' > ws.yaml
printf 'a: [1\n' > bad.yaml
git add -A
if pre-commit run --all-files trailing-whitespace >/dev/null 2>&1; then echo "trailing-whitespace did not catch a violation"; exit 1; fi
if pre-commit run --all-files check-yaml >/dev/null 2>&1; then echo "check-yaml did not catch a violation"; exit 1; fi
echo "pre-commit works offline: clean passes, violations fail"
