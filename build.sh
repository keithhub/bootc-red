#!/usr/bin/env bash
# Build the bootc-red system image with buildah.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# renovate: datasource=docker depName=quay.io/almalinuxorg/almalinux-bootc
BASE_IMAGE="${BASE_IMAGE:-quay.io/almalinuxorg/almalinux-bootc:10.2@sha256:fa5679ce5532efa194b9f344c1a4592100bbf5e5a018c77798510204cb00cb37}"
IMAGE_NAME="${IMAGE_NAME:-localhost/red}"

ctr=
cleanup() {
    if [[ -n "${ctr}" ]]; then
        buildah rm "${ctr}" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

echo "==> From ${BASE_IMAGE}"
ctr=$(buildah from "${BASE_IMAGE}")

echo "==> Provision"
# :Z relabels the bind mount for SELinux-enforcing hosts.
buildah run \
    --volume "${PWD}:/src:ro,Z" \
    "${ctr}" \
    -- /src/setup.sh

echo "==> Commit ${IMAGE_NAME}"
buildah commit --rm "${ctr}" "${IMAGE_NAME}"
ctr=

echo "==> Built ${IMAGE_NAME}"
