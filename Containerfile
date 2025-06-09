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

# Install Linode DNS updater
COPY linode-dns-updater/update-linode-dns.sh /usr/libexec/
COPY linode-dns-updater/update-linode-dns.service /usr/lib/systemd/system/
COPY linode-dns-updater/99-update-linode-dns /usr/lib/NetworkManager/dispatcher.d/

RUN bootc container lint
