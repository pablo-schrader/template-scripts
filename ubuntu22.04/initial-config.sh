#!/bin/bash

vmtoolsd --cmd "info-get guestinfo.ovfenv" > /tmp/ovf_env.xml
TMPXML='/tmp/ovf_env.xml'

# gathering values
date +"%m.%d.%Y %T "; echo "Sorting..."
IP=`cat $TMPXML| grep -e IPaddress |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
NETMASK=`cat $TMPXML| grep -e NetMask |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
GW=`cat $TMPXML| grep -e Gateway |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
HOSTNAME=`cat $TMPXML| grep -e Hostname |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
DNS1=`cat $TMPXML| grep -e DNS1 |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
DNS2=`cat $TMPXML| grep -e DNS2 |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
SSHkey=`cat $TMPXML| grep -e SSH\-key | awk -F\" '{ print $4 }'`
DOMAIN=`expr "$HOSTNAME" | cut -f2- -d.`
#Configure Hostname

hostnamectl set-hostname $HOSTNAME

#Configure Networking

# Creates a backup
cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bk_`date +%Y%m%d%H%M`
# Changes dhcp from 'yes' to 'no'
#sed -i "s/dhcp4: true/dhcp4: false/g" /etc/netplan/01-netcfg.yaml
# Retrieves the NIC information
nic=`ifconfig | awk 'NR==1{print $1}'`
# Creates configuration file 
echo
cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
     $nic
        addresses:
           - $IP/$NETMASK
        gateway4: $GW
        nameservers:
           addresses: [$DNS1, $DNS2]
           search: [$DOMAIN]
EOF
#Apply network configuration
sudo netplan apply

# Applying clouduser User key

echo $SSHkey >> /home/clouduser/.ssh/authorized_keys

#Reverting rc.local to its original
mv /etc/rc.local.bkp /etc/rc.local
