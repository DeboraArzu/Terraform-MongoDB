# AWS architecture
The architecture shown below was created using terraform and AWS as provider.

![architecture](https://github.com/DeboraArzu/Terraform-MongoDB/blob/master/architecture.jpg "Diagram")


# Initial Setup
To create all the resources it is necessary to have the public key and secret key of an AWS user and the key pair name to create the resources and ssh into the bastion.

I used opsworks.pem so you can either set aws_key_name = opsworks or change the key and added it to the key directory and change the private key name on the connection inside the Mongo_Slave1.

```bash
terraform init
terraform apply -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
```
# MongoDB
This project was created to develop a MongoDB Cluster. The master and two slaves, all in different availability zones, as shown below

![Mongo Cluster](https://github.com/DeboraArzu/Terraform-MongoDB/blob/master/mongo_cluster.jpg "Mongo Cluster")

The setup for mongoDB is inside the [scripts directory](https://github.com/DeboraArzu/Terraform-MongoDB/tree/master/scripts "scripts directory") , there are two different scripts one for the MongoDB Master and other one for the slaves.

Also as part of the setup in the configuration_files directory there is a mongod.conf file with the proper configuration for the MongoDB Cluster.

## Setup
To setup the mongo cluster it is necesary to change the [mongod.conf](https://github.com/DeboraArzu/Terraform-MongoDB/tree/master/configuration_files "mongod.conf") file.
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
After mongo is already install in the three instances, the following script is executed on the master mongo instance.
```bash
echo "rs.initiate()" | mongo
echo "rs.add(\"${INSTANCE1}\",\"27017\")" | mongo
echo "rs.add(\"${INSTANCE2}\",\"27017\")" | mongo
```

The first command sets mongo as the master, after this in the mongo shell should appear the word PRIMARY.
The next two commands are to add the slaves.

# CleanUp
The following command is used to delete all created resources.

    terraform destroy -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
