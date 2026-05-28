#!/bin/bash

#colour codes
Bk="\e[30m"	
R="\e[31m"	
G="\e[32m"	
Y="\e[33m"	
B="\e[34m"	
P="\e[35m"	
C="\e[36m"	
W="\e[37m"	

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0cec9364e954bfbdd"
INSTANCE_TYPE="t3.micro"

check_root=$(id -u)

if [ $check_root -ne 0 ]; then
    echo "User doesn't has root privileage, Hence not proceeding with script."
    echo "Run this script with root user"
    exit 1
fi

VALIDATE(){
    if [ $1 -eq 0 ]; then
        echo "$2 installation successful."
    else
        echo "$2 installation failed."
    fi
}

