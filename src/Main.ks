# Configure installation method
# Pinned to the dl.fedoraproject.org master instead of mirrorlists: the
# updates-released-f44 mirrorlist contains stale mirrors serving 404s for
# repodata (comps/updateinfo), which makes anaconda abort with
# "No more mirrors to try" (SourceSetupError). The master is verified complete.
url --url="https://dl.fedoraproject.org/pub/fedora/linux/releases/44/Everything/x86_64/os/"
repo --name=fedora-updates --baseurl="https://dl.fedoraproject.org/pub/fedora/linux/updates/44/Everything/x86_64/" --cost=0
# NOTE: the "orca-" repo IDs below are intentional. Anaconda reads the host's
# /etc/yum.repos.d in no-virt mode and disables every system repo; a kickstart
# repo whose ID collides with a system repo ([google-chrome],
# [fedora-cisco-openh264]) is reconfigured but never re-enabled, so its
# metadata is never loaded -> "No match for argument: google-chrome-stable".
# Unique IDs cannot collide (also avoids the boot.iso's /etc/anaconda.repos.d
# in VM builds). --install is dropped on purpose: the target gets
# google-chrome.repo from the google-chrome-stable RPM (gpgkey added in %post)
# and fedora-cisco-openh264.repo from the fedora-repos RPM.
# codecs.fedoraproject.org is the single canonical source the
# fedora-cisco-openh264 mirrorlist resolves to (verified repomd 200).
repo --name=orca-cisco-openh264 --baseurl="https://codecs.fedoraproject.org/openh264/44/x86_64/"
repo --name=rpmfusion-free --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-44&arch=x86_64"
repo --name=rpmfusion-free-updates --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-44&arch=x86_64" --cost=0
repo --name=rpmfusion-nonfree --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-44&arch=x86_64"
repo --name=rpmfusion-nonfree-updates --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-44&arch=x86_64" --cost=0
repo --name=orca-google-chrome --baseurl="https://dl.google.com/linux/chrome/rpm/stable/x86_64" --cost=0

# Remove all existing partitions
clearpart --all

# zerombr
zerombr

#Create required partitions (BIOS boot partition and /boot)
reqpart --add-boot

# Create Physical Partition
# NOTE: --passphrase is required for unattended installs with --encrypted.
# Change this passphrase to your own before building the real spin.
part pv.01 --asprimary --size=40000 --grow --encrypted --passphrase=fedora-hyprland
volgroup vg pv.01
logvol swap --hibernation --vgname=vg --name=swap
logvol / --vgname=vg --name=fedora-root --size=25000 --grow --fstype=ext4

# Configure Firewall
firewall --enabled

# Configure Network Interfaces
network --onboot=yes --bootproto=dhcp --hostname=sina-laptop

# Configure Keyboard Layouts
keyboard trq

# Configure Language During Installation
lang en_AU

# Services to enable/disable
services --disabled=mlocate-updatedb,mlocate-updatedb.timer,geoclue,avahi-daemon

# Configure Time Zone
timezone Europa/Istanbul

# Configure X Window System
xconfig --startxonboot

# Set Root Password
rootpw --lock

# Create User Account
user --name=Halido --password=12345 --plaintext --groups=wheel

# Configure faillock
authselect enable-feature with-faillock

# (NOT!!!)Perform Installation in Text Mode
#text
# --- TELL THE VM TO TURN OFF WHEN DONE ---
shutdown
# Package Selection
# --ignoremissing is required with the F44/dnf5 backend: the -excludes below
# collide with mandatory members of @core/@standard/@xfce-desktop
# (openssh-server, sssd-common, sssd-kcm, sssd-proxy, abrt-cli, abrt-desktop,
# nfs-utils). dnf5 reports each collision ("matches only excluded packages")
# and anaconda turns resolve warnings into a fatal NonCriticalInstallationError
# in cmdline mode. --ignoremissing sets libdnf5 skip_unavailable=True, which
# silently skips excluded group members the way dnf4 did. Every other package
# name below was verified to resolve in F44 (name or provides).
%packages --ignoremissing
-openssh-server
-gssproxy
-nfs-utils
-sssd*
-abrt*
@core
@standard
@hardware-support
@base-x
@firefox
@fonts
@libreoffice
@multimedia
@networkmanager-submodules
@printing
@xfce-desktop
xfce4-sensors-plugin
@development-tools
dracut-live

#Security
keepassxc
restic
nmap
tcpdump
#wireshark
openssl
firejail
wireguard-tools

#Dev
vim
strace
ffmpeg
ansible
rpmconf
gcc-c++
gcc-gfortran
readline-devel
libX11-devel
libXt-devel
zlib-devel
bzip2-devel
xz-devel
pcre2-devel
libcurl-devel
libffi-devel
python3-devel
python3-virtualenvwrapper
golang
jq
redhat-rpm-config
pykickstart
ipython
ShellCheck
qrencode
genisoimage

#DB
mariadb-server
sqlite

#Usability
rpmfusion-free-release
rpmfusion-nonfree-release
elementary-xfce-icon-theme
redshift-gtk
system-config-printer
xrandr

#Office
google-chrome-stable
gnucash
calibre
irssi
thunderbird
vlc
calc
gimp
transmission-gtk
ristretto
xournal
evince
pinta

%end

# Post-installation Script
%post

#Enable GPG keys for installed repos
cat <<EOF >> /etc/yum.repos.d/google-chrome.repo
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
gpgcheck=1
EOF

cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=10.8.0.1
FallbackDNS=1.1.1.1 1.1.1.2
DNSOverTLS=opportunistic
EOF

cat <<EOF > /etc/NetworkManager/conf.d/dns.conf
[main]
dns=none
systemd-resolved=false
EOF

%end

# Reboot After Installation
# reboot --eject
