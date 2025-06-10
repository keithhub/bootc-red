FROM quay.io/fedora/fedora-bootc:42

RUN dnf -y install \
    NetworkManager-config-server \
    bind-utils \
    curl \
    dnsmasq \
    firewalld \
    iputils \
    podman \
    tmux \
    vim-minimal \
    wget \
    && dnf clean all \
    && echo "Packages installed successfully."

# Copy NetworkManager connection profiles
COPY network/etc /etc
RUN chmod 600 /etc/NetworkManager/system-connections/*.nmconnection

# Install Linode DNS updater
COPY linode-dns-updater/usr /usr

# Set timezone
RUN ln -s ../usr/share/zoneinfo/America/New_York /etc

RUN rm -r /var/cache/* /var/lib/dnf /var/log/dnf5.log

RUN bootc container lint
