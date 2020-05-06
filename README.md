# mongo replica set on centos 7
```
------------+---------------------------+---------------------------+------------
            |                           |                           |
        eth0|10.19.3.2/24           eth0|10.19.3.3/24            eth0|10.19.3.4/24
+-----------+-----------+   +-----------+-----------+   +-----------+-----------+
|    [ node01 ]         |   |       [ node02 ]      |   |      [ node03 ]       |
|                       |   |                       |   |                       |
|  mongodb              |   |      mongodb          |   |        mongodb        |
|  mongo-exporter       |   |      mongo-exporter   |   |      mongo-exporter   |
|                       |   |                       |   |                       |
|                       |   |                       |   |                       |
|                       |   |                       |   |                       |
+-----------------------+   +-----------+-----------+   +-----------------------+

```
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
### Step 3 - Configure Firewalld
In the first step, we already disabled SELinux. For security reasons, we will now enable firewalld on all nodes and open only the ports that are used by MongoDB and SSH.

Install Firewalld with the yum command.
```
# yum -y install firewalld

``` 

Start firewalld and enable it to start at boot time.
```
# systemctl start firewalld
# systemctl enable firewalld
```
Next, open your ssh port and the MongoDB default port 27017.
```
# firewall-cmd --permanent --add-port=22/tcp
# firewall-cmd --permanent --add-port=27017/tcp
# firewall-cmd --reload
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

#security:
#  authorization: enabled
#  keyFile: /var/lib/mongodb-pki/keyfile

replication:
  replSetName: demo-replica-set

```