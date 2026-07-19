#!/usr/bin/env bash
# Provision the bootc-red rootfs. Invoked inside the working container.
set -euo pipefail

SRC=/src

echo "==> Timezone"
ln -srf /usr/share/zoneinfo/America/New_York /etc/localtime

echo "==> Enable CRB and EPEL"
dnf install -y 'dnf-command(config-manager)' epel-release
dnf config-manager --set-enabled crb
# Prefer the EPEL-shipped epel-release (name differs on x86_64_v2)
dnf upgrade -y "$(dnf repoquery --installed --qf '%{name}' --whatprovides epel-release)"

echo "==> Install packages"
dnf install -y \
    NetworkManager-config-server \
    bind-utils \
    clevis-dracut \
    clevis-luks \
    clevis-systemd \
    curl \
    distrobox \
    dnsmasq \
    firewalld \
    iputils \
    podman \
    radvd \
    rsync \
    tmux \
    vdo \
    vim-minimal \
    wget

echo "==> Rebuild initramfs for Clevis"
# bootc maps /root -> var/roothome via symlink; tmpfiles creates the target
# at boot but it is absent during image builds. Dracut always installs /root
# into the initramfs and fails on the dangling link unless the target exists.
mkdir -p /var/roothome
kver=$(echo /usr/lib/modules/*)
kver=${kver##*/}
dracut -vf "/usr/lib/modules/${kver}/initramfs.img" "${kver}"

echo "==> multi-user target"
systemctl set-default multi-user.target

echo "==> Automatic update timers"
mkdir -p /etc/systemd/system/bootc-fetch-apply-updates.timer.d
cat > /etc/systemd/system/bootc-fetch-apply-updates.timer.d/schedule.conf <<'EOF'
[Timer]
OnUnitInactiveSec=
OnCalendar=*-*-* 04:00:00
RandomizedDelaySec=1h
EOF
systemctl enable bootc-fetch-apply-updates.timer podman-auto-update.timer

echo "==> Network configuration"
cp -a "${SRC}/network/etc/." /etc/
chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
printf '%s\n' 'd /var/lib/dnsmasq 0755 root dnsmasq - -' \
    > /usr/lib/tmpfiles.d/dnsmasq.conf
systemctl enable radvd

echo "==> Firewall zones and policies"
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

echo "==> Linode DNS updater"
cp -a "${SRC}/linode-dns-updater/usr/." /usr/
systemctl enable update-linode-dns.timer

echo "==> Tang server"
# TODO: Make it a bound image?
cp -a "${SRC}/tang-server/usr/." /usr/
systemctl enable tang-server.socket
firewall-offline-cmd --new-service tang
firewall-offline-cmd --service tang --set-short "Tang Server"
firewall-offline-cmd --service tang --add-port "7406/tcp"
firewall-offline-cmd --zone dmz --add-service tang
firewall-offline-cmd --zone internal --add-service tang

echo "==> Trim image contents for bootc"
dnf clean all
find /etc/firewalld -name '*.old' -delete
rm -rf /var/cache/* /var/log/* /var/lib/dnf
mv /var/lib/selinux/targeted/active/modules/* /etc/selinux/targeted/modules/
find /var/lib/selinux -empty -delete
rmdir /run/radvd

echo "==> bootc lint"
bootc container lint --fatal-warnings --no-truncate
