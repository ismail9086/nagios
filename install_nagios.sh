#!/bin/bash

# Nagios install script for Amazon Linux 2 / Amazon Linux 2023
# By: ChatGPT for Ismail

set -e

# Variables
NAGIOS_USER=nagios
NAGIOS_GROUP=nagios
NAGIOS_PASS=nagios123
NAGIOS_VERSION=4.4.6
PLUGINS_VERSION=2.3.3

# Install dependencies
sudo yum groupinstall "Development Tools" -y
sudo yum install -y httpd php php-cli gcc glibc glibc-common gd gd-devel make net-snmp unzip wget perl firewalld

# Create user and group
sudo useradd $NAGIOS_USER
sudo groupadd nagcmd
sudo usermod -a -G nagcmd $NAGIOS_USER
sudo usermod -a -G nagcmd apache

# Download and install Nagios
cd /tmp
wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-$NAGIOS_VERSION/nagios-$NAGIOS_VERSION.tar.gz
tar -zxvf nagios-$NAGIOS_VERSION.tar.gz
cd nagios-$NAGIOS_VERSION

./configure --with-command-group=nagcmd
make all
sudo make install
sudo make install-init
sudo make install-commandmode
sudo make install-config
sudo make install-webconf

# Set web access
sudo htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin $NAGIOS_PASS

# Install Nagios Plugins
cd /tmp
wget https://nagios-plugins.org/download/nagios-plugins-$PLUGINS_VERSION.tar.gz
tar -zxvf nagios-plugins-$PLUGINS_VERSION.tar.gz
cd nagios-plugins-$PLUGINS_VERSION
./configure --with-nagios-user=$NAGIOS_USER --with-nagios-group=$NAGIOS_GROUP
make
sudo make install

# Create systemd service
sudo tee /etc/systemd/system/nagios.service > /dev/null <<EOF
[Unit]
Description=Nagios Core Monitoring Server
After=network.target httpd.service

[Service]
Type=simple
ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg
ExecReload=/bin/kill -HUP \$MAINPID
User=nagios
Group=nagios
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable httpd --now
sudo systemctl enable nagios --now

# Firewall (if applicable)
if command -v firewall-cmd >/dev/null; then
  sudo systemctl start firewalld
  sudo firewall-cmd --add-service=http --permanent
  sudo firewall-cmd --reload
fi

echo ">>> Nagios installation completed successfully!"
echo ">>> Access it at: http://<your-ec2-ip>/nagios"
echo ">>> Login with: nagiosadmin / $NAGIOS_PASS"
