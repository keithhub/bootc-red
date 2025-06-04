build:
    podman build . -t localhost/red

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
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type anaconda-iso \
        localhost/red
