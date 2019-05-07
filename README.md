# Terraform-MongoDB
Terraform exercise using AWS provider to launch this architecture https://docs.aws.amazon.com/quickstart/latest/mongodb/architecture.html

# Initial Setup
```bash
terraform init
terraform apply -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
```
# MongoDB
The setup for mongoDB is inside the scripts directory , there are two different scripts one for the MongoDB Master and other one for the slaves.
Also as part of the setup in the configuration_files directory there is a mongod.conf file with the proper configuration for the MongoDB Cluster.
# CleanUp
    terraform destroy -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
