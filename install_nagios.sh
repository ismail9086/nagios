#!/bin/bash

# Exit on error
set -e

# ========================
# Variables
# ========================
NAGIOS_USER="nagios"
NAGIOS_GROUP="nagios"
APACHE_USER="apache"
NAGIOS_VERSION="4.4.6"
SRC_DIR="/usr/local/src"
NAGIOS_HOME="/usr/local/nagios"
NAGIOS_TAR="nagios-${NAGIOS_VERSION}.tar.gz"
NAGIOS_URL="https://assets.nagios.com/downloads/nagioscore/releases/${NAGIOS_TAR}"

# ========================
# Installing Dependencies
# ========================
echo ">>> Installing Dependencies..."
sudo yum install -y gcc glibc glibc-common wget unzip httpd php \
gd gd-devel perl postfix make net-snmp openssl-devel

echo ">>> Dependencies Installed Successfully."

# ========================
# Creating Nagios User
# ========================
echo ">>> Creating Nagios User..."
sudo useradd -r -s /sbin/nologin $NAGIOS_USER || echo "$NAGIOS_USER already exists"
sudo groupadd -f $NAGIOS_GROUP
sudo usermod -aG $NAGIOS_GROUP $APACHE_USER

echo ">>> Nagios User Setup Complete."

# ========================
# Downloading Nagios Core
# ========================
echo ">>> Downloading Nagios Core..."
cd $SRC_DIR
sudo wget -q --show-progress $NAGIOS_URL
sudo tar -zxvf $NAGIOS_TAR

echo ">>> Extracted Nagios Source Code."

# ========================
# Compiling and Installing
# ========================
cd $SRC_DIR/nagios-$NAGIOS_VERSION
echo ">>> Configuring Nagios..."
./configure --with-httpd-conf=/etc/httpd/conf.d --with-command-group=$NAGIOS_GROUP

echo ">>> Building Nagios..."
make all

echo ">>> Installing Nagios..."
sudo make install
sudo make install-commandmode
sudo make install-init
sudo make install-config
sudo make install-webconf

echo ">>> Nagios Core Installed Successfully."

# ========================
# Creating Systemd Service
# ========================
echo ">>> Creating Nagios systemd service..."
sudo tee /etc/systemd/system/nagios.service > /dev/null <<EOF
[Unit]
Description=Nagios Core Monitoring Server
After=network.target httpd.service

[Service]
Type=forking
ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/usr/local/nagios/var/nagios.pid
User=nagios
Group=nagios

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nagios

echo ">>> Nagios systemd service created."

# ========================
# Setting Web Access
# ========================
echo ">>> Setting Web Access for Nagios..."
sudo htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin nagios123

echo ">>> Web UI credentials created for user: nagiosadmin (password: nagios123)"

# ========================
# Starting Services
# ========================
echo ">>> Starting Apache and Nagios..."
sudo systemctl restart httpd
sudo systemctl start nagios
