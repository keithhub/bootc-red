FROM quay.io/fedora/fedora-bootc:42


# Set timezone
RUN ln -sr /usr/share/zoneinfo/America/New_York /etc

# Install native packages
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
RUN echo "d /var/lib/dnsmasq 0755 root dnsmasq - -" > /usr/lib/tmpfiles.d/dnsmasq.conf

# Install Linode DNS updater
COPY linode-dns-updater/usr /usr

RUN rm -r /var/cache/* /var/log/*
RUN rm -r /var/lib/dnf

RUN bootc container lint
