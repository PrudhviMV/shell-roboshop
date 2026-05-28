#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0cec9364e954bfbdd"
INSTANCE_TYPE="t3.micro"
DOMAIN="prudhvii.fun"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=mongodb}]" --query 'Instances[0].InstanceId' --output text)

    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
        R53_record="$instance.$DOMAIN"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
        R53_record="$instance.$DOMAIN"
    fi
        echo -e "$instance:$IP"
done