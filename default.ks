# Installation method
cmdline

# Network
network --bootproto=dhcp --device=link --activate --onboot=on

# Language and keyboard settings
lang en_US.UTF-8
keyboard us

# Timezone
timezone America/New_York --utc

# Clear MBR
zerombr
clearpart --all --initlabel --disklabel msdos

# Partitioning
#part biosboot --fstype=biosboot --size=1
part /boot --fstype=ext4 --size=1024
part swap --fstype=swap --size=8192
part / --fstype=xfs --grow --size=1

# Bootloader
bootloader --location=mbr

# Root
rootpw --lock

# User
user --name keith --groups=wheel --iscrypted --password="$6$SqQklh3y2BEql6ZV$al0zgxuRU3RTJoLFqrHBkCLKN7vnoKEM.sQ2gs4Del1IFY8s2A0ZvlMmOZvP8NH0Stjx.MTEodHkMalLflYU1."
sshkey --username keith "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXUzN2aSID7Zd5lARAw+mC4eORXOWjueVkhTNjd9R/J khubbard@kh8"

# Reboot
reboot
