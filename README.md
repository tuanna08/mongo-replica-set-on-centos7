# mongo replica set on centos 7
```
------------+---------------------------+---------------------------+------------
            |                           |                           |
        eth0|10.19.3.2/24           eth0|10.19.3.3/24           eth0|10.19.3.4/24
+-----------+-----------+   +-----------+-----------+   +-----------+-----------+
|    [ NoSQL01 ]        |   |       [ NoSQL01 ]     |   |      [ NoSQL01 ]      |
|                       |   |                       |   |                       |
|  mongodb              |   |      mongodb          |   |        mongodb        |
|  mongo-exporter       |   |      mongo-exporter   |   |      mongo-exporter   |
|                       |   |                       |   |                       |
|                       |   |                       |   |                       |
|                       |   |                       |   |                       |
+-----------------------+   +-----------+-----------+   +-----------------------+


```
### Step 1 - Disable selinux

- Change value 'enforcing' to 'disabled'.
```
# vim /etc/sysconfig/selinux
```
- find and repalce
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

### Step 2 - setup mongodb
- B1: edit hosts
```
# vi /etc/hosts
10.19.3.2       NoSQL01.local NoSQL01
10.19.3.3       NoSQL02.local NoSQL02
10.19.3.4       NoSQL03.local NoSQL03
```

- B2: Configure the package management system (yum)
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

- B3: Install mongodb
```
# yum install -y mongodb-org
```

### Step 3 - Configure Firewalld
In the first step, we already disabled SELinux. For security reasons, we will now enable firewalld on all nodes and open only the ports that are used by MongoDB and SSH.

- b1: Install Firewalld with the yum command.
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

### Step 4 - Config replica set

- b1: Edit ip listening and add config
    ```
    # vi /etc/mongod.conf

    net:
      port: 27017
      bindIp: 0.0.0.0  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.

    operationProfiling:
      mode: "slowOp"
      slowOpThresholdMs: 50

    replication:
      replSetName: demo-replica-set
    ```

- and restart

    ```
    $ sudo systemctl enable mongod
    $ sudo systemctl restart mongod
    ```

- Verify that the port is listening:

    ```
    root@node03:~# sudo netstat -tulpn | grep 27017
    tcp        0      0 0.0.0.0:27017           0.0.0.0:*               LISTEN      3255/mongod
    ```

- b2:  Initialize the MongoDB Replica Set
When mongodb starts for the first time it allows an exception that you can logon without authentication to create the root account, but only on localhost. The exception is only valid until you create the user:
```
root@node01:~# mongo --host 127.0.0.1 --port 27017
MongoDB shell version v4.0.14
connecting to: mongodb://127.0.0.1:27017/?gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("1a91c1e2-e484-4734-8296-54c92ce6a5e1") }
MongoDB server version: 4.0.14
Welcome to the MongoDB shell.
For interactive help, type "help".
For more comprehensive documentation, see
	http://docs.mongodb.org/
Questions? Try the support group
	http://groups.google.com/group/mongodb-user
>
```

- Switch to the admin database and initialize the mongodb replicaset:
```
> use admin
switched to db admin
> rs.initiate()
{
    "info2" : "no configuration specified. Using a default configuration for the set",
    "me" : "node01:27017",
    "ok" : 1
}
```
- edit hostname member
```
> cfg = rs.conf()
> cfg.members[0].host = "NoSQL01.local:27017"
> rs.reconfig(cfg)
```

- Now that we have initialized our replicaset config, create the admin user and apply the admin role:
```
admin = db.getSiblingDB("admin")
admin.createUser(
  {
    user: "fred",
    pwd: passwordPrompt(), // or cleartext password
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  }
)
```
- Authenticate as the user administrator
```
db.getSiblingDB("admin").auth("fred", passwordPrompt()) // or cleartext password
```

- Create the cluster administrator.
```
db.getSiblingDB("admin").createUser(
  {
    "user" : "ravi",
    "pwd" : passwordPrompt(),     // or cleartext password
    roles: [ { "role" : "clusterAdmin", "db" : "admin" } ]
  }
)
```
- login mongo node
```
# mongo --host demo-replica-set/node01:27017 --username ravi --password 123456abcA --authenticationDatabase admin
```

- add member node
    ```
    demo-replica-set:PRIMARY> rs.add("NoSQL02.local:27017")
    {
            "ok" : 1,
            "$clusterTime" : {
                    "clusterTime" : Timestamp(1588761944, 1),
                    "signature" : {
                            "hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
                            "keyId" : NumberLong(0)
                    }
            },
            "operationTime" : Timestamp(1588761944, 1)
    }
    ```

- add Arbiter

    ```
    demo-replica-set:PRIMARY> rs.addArb("NoSQL03.local:27017")
    {
            "ok" : 1,
            "$clusterTime" : {
                    "clusterTime" : Timestamp(1588755810, 1),
                    "signature" : {
                            "hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
                            "keyId" : NumberLong(0)
                    }
            },
            "operationTime" : Timestamp(1588755810, 1)
    }
    demo-replica-set:PRIMARY>
    ```