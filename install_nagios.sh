#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
NAGIOS_USER="nagios"
NAGIOS_GROUP="nagios"
APACHE_USER="apache"
NAGIOS_VERSION="4.4.6"
PLUGINS_VERSION="2.3.3"
SRC_DIR="/usr/local/src"
NAGIOS_HOME="/usr/local/nagios"

echo "=========================="
echo "Installing Dependencies..."
echo "=========================="
sudo yum install -y gcc glibc glibc-common wget unzip httpd php \
  gd gd-devel perl postfix make net-snmp openssl-devel xinetd

echo "=========================="
echo "Creating Nagios User..."
echo "=========================="
sudo useradd $NAGIOS_USER
sudo groupadd $NAGIOS_GROUP
sudo usermod -a -G $NAGIOS_GROUP $APACHE_USER

echo "=========================="
echo "Downloading Nagios Core..."
echo "=========================="
cd $SRC_DIR
sudo wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-$NAGIOS_VERSION.tar.gz
sudo tar zxvf nagios-$NAGIOS_VERSION.tar.gz
cd nagios-$NAGIOS_VERSION

echo "=========================="
echo "Compiling and Installing Nagios..."
echo "=========================="
sudo ./configure --with-httpd-conf=/etc/httpd/conf.d
sudo make all
sudo make install
sudo make install-init
sudo make install-commandmode
sudo make install-config
sudo make install-webconf

echo "=========================="
echo "Setting Nagios Web Access..."
echo "=========================="
sudo htpasswd -bc /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

echo "=========================="
echo "Downloading and Installing Nagios Plugins..."
echo "=========================="
cd $SRC_DIR
sudo wget https://nagios-plugins.org/download/nagios-plugins-$PLUGINS_VERSION.tar.gz
sudo tar zxvf nagios-plugins-$PLUGINS_VERSION.tar.gz
cd nagios-plugins-$PLUGINS_VERSION
sudo ./configure --with-nagios-user=$NAGIOS_USER --with-nagios-group=$NAGIOS_GROUP
sudo make
sudo make install

echo "=========================="
echo "Enabling Services..."
echo "=========================="
sudo systemctl enable httpd
sudo systemctl enable nagios

echo "=========================="
echo "Starting Services..."
echo "=========================="
sudo systemctl start httpd
sudo systemctl start nagios

echo "=========================="
echo "Nagios Installed Successfully!"
echo "Access it at: http://<your-server-ip>/nagios"
echo "Username: nagiosadmin | Password: nagiosadmin"
echo "=========================="
