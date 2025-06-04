FROM quay.io/fedora/fedora-bootc:42

RUN dnf -y install \
    firewalld \
    podman \
    dnsmasq \
    NetworkManager-config-server \
    curl \
    wget \
    vim-minimal \
    iputils \
    bind-utils \
    && dnf clean all \
    && echo "Packages installed successfully."

# Copy NetworkManager connection profiles
COPY --chown=root:root --chmod=600 *.nmconnection \ /etc/NetworkManager/system-connections/
