#!/bin/bash

echo "Create by Openstack Company"

#echo "10.19.3.2  node01" >> /etc/hosts
#echo "10.19.3.3  node02" >> /etc/hosts
#echo "10.19.3.4  node03" >> /etc/hosts

# Configure the package management system (yum)

FILE=/etc/yum.repos.d/mongodb-org-4.2.repo

if [ -f "$FILE" ]; then
  rm /etc/yum.repos.d/mongodb-org-4.2.repo
fi

cat <<'EOF' >> /etc/yum.repos.d/mongodb-org-4.2.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc 
EOF

#Install mongodb
yum install -y mongodb-org

# stop and disable firewalld

#systemctl disable firewalld
#systemctl stop firewalld


# config firewalld
yum -y install firewalld
systemctl start firewalld
systemctl enable firewalld

# Next, open your ssh port and the MongoDB default port 27017.

firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=27017/tcp
firewall-cmd --reload






echo "install done!"