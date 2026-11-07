# renovate: datasource=docker depName=quay.io/centos-bootc/bootc-image-builder
bootc_image_builder := "quay.io/centos-bootc/bootc-image-builder:latest@sha256:4d8a0d9d173a9f450ff42d70777e1e0a6681a68f5c0f5084b65222eceb1f4d05"

build:
    ./build.sh

make-iso:
    podman save localhost/red | sudo podman load
    sudo podman run --rm -it \
        --network=host \
        --pull=newer \
        --privileged \
        --security-opt label=type:unconfined_t \
        -v ./config.toml:/config.toml:ro \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        {{bootc_image_builder}} \
        --type anaconda-iso \
        localhost/red
