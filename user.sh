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

START_TIME=$(date +%s)
#END_TIME=$(date +%s)

echo "Script started at $START_TIME"

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
        VALIDATE $? "Roboshop User is added"
    else
        echo "User is already present"
    fi

mkdir -p /app 
VALIDATE $? "Creating App directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Fetching User component Code"
cd /app 
VALIDATE $? "Traversing into User directory"

unzip /tmp/user.zip
VALIDATE $? "Unzipping code"

npm install 
VALIDATE $? "Compiling NPM"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user service file"

systemctl daemon-reload
VALIDATE $? "Reloading daemon"

systemctl enable user 
VALIDATE $? "Enabling user service"

systemctl start user
VALIDATE $? "starting user service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"