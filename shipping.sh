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
MYSQL_HOST="mysql.prudhvii.fun"
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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Roboshop User is added"
    else
        echo "User is already present"
    fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Fetching shipping component Code"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Deleting code in app directory"


cd /app &>>$LOG_FILE
VALIDATE $? "Traversing into shipping app directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping code"

cd /app &>>$LOG_FILE
VALIDATE $? "traversed into app directory"

mvn clean package &>>$LOG_FILE
VALIDATE $? "compiling and cleaning package"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving package"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying shipping service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading daemon"

sudo systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling shipping service"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping service"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"