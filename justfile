# renovate: datasource=docker depName=quay.io/centos-bootc/bootc-image-builder
bootc_image_builder := "quay.io/centos-bootc/bootc-image-builder:latest@sha256:dab86ee6b46dcade411b37f4e70b07d93b6a06da0dbfec6fe89247a220e0d9f8"

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
