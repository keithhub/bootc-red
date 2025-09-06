FROM quay.io/almalinuxorg/almalinux-bootc:10.0

# Set timezone
RUN ln -sr /usr/share/zoneinfo/America/New_York /etc/localtime


# Install common packages

RUN <<EORUN
dnf install -y dnf-plugins-core epel-release
dnf config-manager --set-enabled crb
dnf install -y \
    NetworkManager-config-server \
    bind-utils \
    curl \
    distrobox \
    dnsmasq \
    firewalld \
    iputils \
    podman \
    rsync \
    tmux \
    vim-minimal \
    wget \
    ;
echo "Packages installed successfully."
EORUN


# Install and enable Clevis
RUN dnf install -y clevis-dracut clevis-luks clevis-systemd \
    && kver=$(cd /usr/lib/modules && echo *) \
    && dracut -vf /usr/lib/modules/$kver/initramfs.img $kver


# Install VDO
RUN dnf install -y vdo


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

firewall-offline-cmd --zone external --add-service dhcpv6-client

firewall-offline-cmd --zone internal --add-protocol icmp
firewall-offline-cmd --zone internal --add-protocol ipv6-icmp
firewall-offline-cmd --zone internal --add-service dhcp
firewall-offline-cmd --zone internal --add-service dns
firewall-offline-cmd --zone internal --remove-service-from-zone cockpit
firewall-offline-cmd --zone internal --remove-service-from-zone samba-client

firewall-offline-cmd --new-ipset dmz --type hash:ip
firewall-offline-cmd --zone dmz --add-source ipset:dmz

firewall-offline-cmd --new-policy fwd_outbound
firewall-offline-cmd --policy fwd_outbound --add-ingress-zone internal
firewall-offline-cmd --policy fwd_outbound --add-egress-zone external
firewall-offline-cmd --policy fwd_outbound --add-egress-zone dmz
firewall-offline-cmd --policy fwd_outbound --set-target ACCEPT

firewall-offline-cmd --new-policy fwd_inbound_ipv6
firewall-offline-cmd --policy fwd_inbound_ipv6 --add-ingress-zone external
firewall-offline-cmd --policy fwd_inbound_ipv6 --add-ingress-zone dmz
firewall-offline-cmd --policy fwd_inbound_ipv6 --add-egress-zone internal
firewall-offline-cmd --policy fwd_inbound_ipv6 --family ipv6 --set-target ACCEPT
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
firewall-offline-cmd --new-service tang
firewall-offline-cmd --service tang --set-short "Tang Server"
firewall-offline-cmd --service tang --add-port "7406/tcp"
firewall-offline-cmd --zone dmz --add-service tang
firewall-offline-cmd --zone internal --add-service tang
EOF


# Clean up
RUN dnf clean all
RUN find /etc/firewalld -name '*.old' -delete
RUN rm -r /var/cache/* /var/log/*
RUN rm -r /var/lib/dnf

RUN bootc container lint
