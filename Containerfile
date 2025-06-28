FROM --platform=linux/amd64/v2 quay.io/almalinuxorg/almalinux-bootc:10.0

# Set timezone
RUN ln -sr /usr/share/zoneinfo/America/New_York /etc/localtime


# Install common packages
RUN <<EORUN
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf install -y \
    NetworkManager-config-server \
    bind-utils \
    curl \
    distrobox \
    dnsmasq \
    firewalld \
    iputils \
    podman \
    tmux \
    vim-minimal \
    wget \
    ;
dnf clean all
echo "Packages installed successfully."
EORUN


# Set default target
RUN systemctl set-default multi-user.target

# Allow auto-updates
RUN systemctl enable bootc-fetch-apply-updates.timer
RUN systemctl enable podman-auto-update.timer


# Copy NetworkManager connection profiles
COPY network/etc /etc
RUN chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
RUN echo "d /var/lib/dnsmasq 0755 root dnsmasq - -" > /usr/lib/tmpfiles.d/dnsmasq.conf

# Set up firewall
RUN <<EOF
set -euo pipefail

firewall-offline-cmd --zone=external --add-service=dhcpv6-client
EOF

# Install Linode DNS updater
COPY linode-dns-updater/usr /usr
RUN systemctl enable update-linode-dns.timer


# Set up Tang service
# TODO: Make it a bound image?
COPY tang-server/usr /usr
RUN systemctl enable tang-server.socket
RUN <<EOF
set -euo pipefail
firewall-offline-cmd --new-service=tang
firewall-offline-cmd --service=tang --set-short="Tang Server"
firewall-offline-cmd --service=tang --add-port="7406/tcp"
firewall-offline-cmd --zone=dmz --add-service=tang
firewall-offline-cmd --zone=nm-shared --add-service=tang
EOF


# Clean up
RUN find /etc/firewalld -name '*.old' -delete
RUN rm -r /var/cache/* /var/log/*
RUN rm -r /var/lib/dnf

RUN bootc container lint
