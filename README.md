# Terraform-MongoDB
Terraform exercise using AWS provider to launch this architecture https://docs.aws.amazon.com/quickstart/latest/mongodb/architecture.html

# Initial Setup
```bash
terraform init
terraform apply -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
```
# MongoDB
# CleanUp
    terraform destroy -var 'access_key=PUBLIC_KEY' -var 'secret_key=SECRET_KEY' -var 'aws_key_name= KEY_NAME'
