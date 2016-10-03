#!/usr/bin/env bash

# Full source code available at https://github.com/janesmae/postinstall
# See LICENSE for the complete license text
# Contributions are welcome. See CONTRIBUTIONS.md for more info.

# Declaring a few variables
ADD_SUDO_USER=0 # Set to 1 to add new user with sudo privileges
USER_LOGIN=sudouser # Declare a new user login name
USER_SSH_KEY='ssh-ed25519 AAAA...' # Users public ssh key

#------------------------------------------------------------------------------#

# This script must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Function for setting up firewall
FirewallSetup ()
{

    echo "Setting up default firewall rules"
    # Firewall default rules, deny everything
    ufw default deny incoming
    ufw default deny outgoing

    # Firewall rules
    # - allow HTTP and HTTPS traffic to the outside
    # - limit incoming SSH connections
    ufw allow out http
    ufw allow out https
    ufw allow out dns
    ufw allow out ntp
    ufw limit ssh

    echo "Making changes to firewall config, log to separate file and enable on boot"
    # Changes to firewall config, log to separate file and enable on boot
    sed -i '/~/s/^#//g' /etc/rsyslog.d/20-ufw.conf
    sed -i 's/ENABLED=no/ENABLED=yes/g' /etc/ufw/ufw.conf

    echo "Restarting affected services and enabling firewall"
    # Restart affected services and enable Firewall
    /etc/init.d/rsyslog restart > /dev/null
    ufw --force enable > /dev/null

}

# Function for OpenSSH hardening
# !!!WARNING!!! This script will disable root login via SSH
OpenSSHHardening ()
{

    echo "Fix OpenSSH config"
    # Fix OpenSSH config
    echo "" > /etc/ssh/sshd_config

    # Hardened OpenSSH config
    # Ref: https://cipherli.st
    # Ref: https://stribika.github.io/2015/01/04/secure-secure-shell.html
    # Ref: https://wiki.mozilla.org/Security/Guidelines/OpenSSH#Modern_.28OpenSSH_6.7.2B.29
    cat > /etc/ssh/sshd_config << EOL
Protocol 2

# Supported HostKey algorithms by order of preference.
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com

# Password based logins are disabled - only public key based logins are allowed.
AuthenticationMethods publickey

# LogLevel VERBOSE logs user's key fingerprint on login. Needed to have a clear audit track of which key was using to log in.
LogLevel VERBOSE

# Log sftp level file access (read/write/etc.) that would not be easily logged otherwise.
Subsystem sftp  /usr/lib/ssh/sftp-server -f AUTHPRIV -l INFO

# Root login is not allowed for auditing reasons. This is because it's difficult to track which process belongs to which root user:
#
# On Linux, user sessions are tracking using a kernel-side session id, however, this session id is not recorded by OpenSSH.
# Additionally, only tools such as systemd and auditd record the process session id.
# On other OSes, the user session id is not necessarily recorded at all kernel-side.
# Using regular users in combination with /bin/su or /usr/bin/sudo ensure a clear audit track.
PermitRootLogin No

# Use kernel sandbox mechanisms where possible in unprivilegied processes
# Systrace on OpenBSD, Seccomp on Linux, seatbelt on MacOSX/Darwin, rlimit elsewhere.
UsePrivilegeSeparation sandbox
EOL

    echo "Remove and generate new host keys"
    # Remove and generate new host keys
    shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
    ssh-keygen -A

    echo "Restart OpenSSH server"
    # Restarting OpenSSH
    /etc/init.d/ssh restart

}

# Function for adding new user with sudo privileges
NewSudoUser ()
{

    echo "Add new user with sudo privileges"
    # Add new user
    # Make sure no password and unlocked account
    # Add user to sudoers
    useradd -m -d /home/$USER_LOGIN $USER_LOGIN
    usermod -p '*' $USER_LOGIN
    echo " ${USER_LOGIN} ALL=NOPASSWD: ALL" >> /etc/sudoers

    # Add public ssh key to authorized_keys for the new user
    mkdir /home/$USER_LOGIN/.ssh
    echo $USER_SSH_KEY > /home/janesmae/.ssh/authorized_keys
    chown -R $USER_LOGIN.$USER_LOGIN /home/$USER_LOGIN/.ssh

    # Set correct permissions to user home directory
    chmod go-w /home/$USER_LOGIN
    chmod 700 /home/$USER_LOGIN/.ssh
    chmod 644 /home/$USER_LOGIN/.ssh/authorized_keys

    # The new sshd_config denies root login. Root shouldn't have ssh keys either.
    # Comment the following 2 lines to skip that
    shred -u ~/.ssh/*
    rm -Rf ~/.ssh

}

#------------------------------------------------------------------------------#

echo "Running apt-get update and installing essential software"
# Run updates, install core software
apt-get -qq update
apt-get -qq dist-upgrade
apt-get -qq install build-essential vim sudo git-core curl ufw

echo "Setting timezone to UTC"
# Set timezone to UTC
sudo timedatectl set-timezone UTC

# Setting up firewall
FirewallSetup

# OpenSSH hardening
OpenSSHHardening

# Add new user with sudo privileges
if [ "$ADD_SUDO_USER" -eq 1 ] ; then NewSudoUser ; fi

echo "Done!"
exit 0
