#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
Mongo_host="mongodb.prudhvii.fun"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y
VALIDATE $? "Installing Nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Roboshop user added"
else
    echo "User is already present"
fi

mkdir /app 
VALIDATE $? "Creating Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Fetching Code to server"

cd /app
VALIDATE $? "traversing into app directory"

rm -rf /app/*
VALIDATE $? "Removing old code"

unzip /tmp/catalogue.zip
VALIDATE $? "unzip code"

npm install 
VALIDATE $? "Install NPM"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Adding catalogue repo"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable catalogue 
VALIDATE $? "Enable catalogue"

systemctl start catalogue
VALIDATE $? "Start catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-mongosh -y
VALIDATE $? "Installing Mongodb"

mongosh --host $Mongo_host </app/db/master-data.js
VALIDATE $? "Loading Master data"

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"