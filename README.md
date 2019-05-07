# AWS architecture
![architecture](https://github.com/DeboraArzu/Terraform-MongoDB/blob/master/architecture.jpg "Diagram")

# Initial Setup
```bash
terraform init
terraform apply -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
```
# MongoDB
The setup for mongoDB is inside the scripts directory , there are two different scripts one for the MongoDB Master and other one for the slaves.
Also as part of the setup in the configuration_files directory there is a mongod.conf file with the proper configuration for the MongoDB Cluster.
## Setup
To setup the mongo cluster it is necesary to change the mongod.conf file.
```
# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0  # Enter 0.0.0.0,:: to bind to all IPv4 and IPv6 addresses or, alternatively, use the net.bindIpAll setting.

#security:

#operationProfiling:

replication:
    replSetName: "mongoreplica"
```
After mongo is already install in the 3 instances, the following script is run on the master mongo instances.
```bash
echo "rs.initiate()" | mongo
echo "rs.add(\"${INSTANCE1}\",\"27017\")" | mongo
echo "rs.add(\"${INSTANCE2}\",\"27017\")" | mongo
```

# CleanUp
    terraform destroy -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
