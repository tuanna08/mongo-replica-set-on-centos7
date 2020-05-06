# mongo-replica-set-on-centos7-by-script

### b1: disable selinux

```
# vim /etc/sysconfig/selinux
```

- Change value 'enforcing' to 'disabled'.
```
SELINUX=disabled
```

- Save and exit, then reboot the servers.
```
# reboot
```

- Check the SELinux status with the command.

```
# sestatus
```

### setup mongodb

- B1: ADD VERSION
```
# cat <<'EOF' >> /etc/yum.repos.d/mongodb-org-4.2.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc 
EOF
```

- B2: INSTALL MONGODB

```
# yum install -y mongodb-org
```

- B3: edit config
```
# mkdir /var/lib/mongodb-pki

```
Use openssl or anything similar to generate a random key(on node 1):
```
# openssl rand -base64 741 > keyfile
# scp ./keyfile mg-node02:/root/keyfile
# scp ./keyfile mg-node03:/root/keyfile

```


- on all node

```

# mv keyfile /var/lib/mongodb-pki/keyfile
# chmod 600 /var/lib/mongodb-pki/keyfile
# chown -R mongodb:mongodb /var/lib/mongodb-pki
```
```
# vi /etc/mongod.conf
```

  + edit
  
```
# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.

operationProfiling:
  mode: "slowOp"
  slowOpThresholdMs: 50

security:
  authorization: enabled
  keyFile: /var/lib/mongodb-pki/keyfile

replication:
  replSetName: demo-replica-set

```