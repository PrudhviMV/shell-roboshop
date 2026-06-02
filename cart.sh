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

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Roboshop User is added"
    else
        echo "User is already present"
    fi

mkdir -p /app &>>LOG_FILE
VALIDATE $? "Creating App directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>LOG_FILE
VALIDATE $? "Fetching cart component Code"

cd /app &>>LOG_FILE
VALIDATE $? "Traversing into cart app directory"

unzip /tmp/cart.zip &>>LOG_FILE
VALIDATE $? "Unzipping code"

npm install &>>LOG_FILE
VALIDATE $? "Compiling NPM"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>LOG_FILE
VALIDATE $? "Copying cart service file"

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "Reloading daemon"

systemctl enable cart &>>LOG_FILE
VALIDATE $? "Enabling cart service"

systemctl start cart &>>LOG_FILE
VALIDATE $? "starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"