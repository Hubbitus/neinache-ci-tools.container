#!/bin/sh
# Runs inside the image with no network (see the smoke job). Every baked tool
# must answer, and `mise install` against the baked config must not try to fetch.
set -eu

for t in java python3 node pnpm kubectl yq helm kustomize argocd sops age lychee \
         podman terraform tflint trivy go bats shellcheck jq git openssl pre-commit; do
  command -v "$t" >/dev/null || { echo "missing: $t"; exit 1; }
done

java -version
python3 --version
node --version
pnpm --version
kubectl version --client=true
yq --version
helm version
kustomize version
argocd version --client
sops --version
age --version
lychee --version
# argv[0] is load-bearing: Quarkus accepts only a line that starts with "podman version".
podman --version | grep -q '^podman version'
terraform version
tflint --version
trivy --version
go version
bats --version
shellcheck --version
jq --version
git --version
openssl version
pre-commit --version
test -x "$JAVA_HOME/bin/native-image"

cd /opt/neinache
mise install -y
echo "mise tools work offline"
