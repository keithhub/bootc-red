# renovate: datasource=docker depName=quay.io/centos-bootc/bootc-image-builder
bootc_image_builder := "quay.io/centos-bootc/bootc-image-builder:latest@sha256:2b52843ea2bfda73b0a08d97e76b734393b1d3a804681b9fabb26723bd3a2f0b"

build:
    podman build --platform linux/amd64/v2 . -t localhost/red

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
