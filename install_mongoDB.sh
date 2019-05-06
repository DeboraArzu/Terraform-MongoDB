#! /bin/bash
sudo yum update -y
sudo echo "[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo
sudo yum install -y mongodb-org
sudo yum install libcurl openssl
sudo service mongod start
sudo chkconfig mongod on