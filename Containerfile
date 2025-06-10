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

# Install Linode DNS updater
COPY linode-dns-updater/usr /usr

# Copy NetworkManager connection profiles
COPY --chown=root:root --chmod=600 *.nmconnection \ /etc/NetworkManager/system-connections/

# Set timezone
RUN ln -s ../usr/share/zoneinfo/America/New_York /etc

RUN rm -r /var/cache/* /var/lib/dnf /var/log/dnf5.log

RUN bootc container lint
