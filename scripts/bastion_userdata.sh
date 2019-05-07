#!/bin/bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 --region us-east-1 associate-address --instance-id $INSTANCE_ID --allocation-id ${EIP_ID}
