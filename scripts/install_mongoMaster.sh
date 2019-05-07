#! /bin/bash
yum update -y
echo "[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo
yum install -y mongodb-org
yum install libcurl openssl
cp /home/ec2-user/mongod.conf /etc/mongod.conf
rm -rf /var/lib/mongo/mongod.lock
rm -rf /var/run/mongodb/mongod.pid
service mongod restart
chkconfig mongod on

# Mongo Cluster setup
echo "rs.initiate()" | mongo
echo "rs.add(\"${instance1}\",\"27017\")" | mongo
echo "rs.add(\"${instance2}\",\"27017\")" | mongo