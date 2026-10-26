# renovate: datasource=docker depName=quay.io/centos-bootc/bootc-image-builder
bootc_image_builder := "quay.io/centos-bootc/bootc-image-builder:latest@sha256:b858892139e0779d48869a4dd8cbbc4e257da49f5a4b502824a55d221ed65a55"

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
