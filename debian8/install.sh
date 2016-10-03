#!/usr/bin/env bash

# Full source code available at https://github.com/janesmae/postinstall

# This script must be run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Running apt-get update and installing essential software"
# Run updates, install core software
apt-get -qq update
apt-get -qq dist-upgrade
apt-get -qq install build-essential vim sudo git-core curl ufw

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

echo "Making changes to firewall config, log to separate file and enable on login"
# Changes to firewall config, log to separate file and enable on login
sed -i '/~/s/^#//g' /etc/rsyslog.d/20-ufw.conf
sed -i 's/ENABLED=no/ENABLED=yes/g' /etc/ufw/ufw.conf

echo "Setting timezone to UTC"
# Set timezone to UTC
sudo timedatectl set-timezone UTC

echo "Restarting affected services and enabling firewall"
# Restart affected services and enable Firewall
/etc/init.d/rsyslog restart > /dev/null
ufw --force enable > /dev/null

echo "Done!"
exit 0
