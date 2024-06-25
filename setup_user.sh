#!/bin/bash

# 0. Create variable for IP addresses
MONGODB_SERVER_IP="mongodb.3gb.online"
REDIS_SERVER_IP="redis.3gb.online"

# 1. Install NodeJS and enable version 18
dnf install -y nodejs
dnf module disable -y nodejs
dnf module enable -y nodejs:18

# 2. Install NodeJS
dnf install -y nodejs

# 3. Add application user
useradd roboshop

# 4. Set up an app directory
mkdir /app

# 5. Download the application code to the created app directory
curl -L -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip

# 6. Unzip the downloaded file to /app
unzip /tmp/user.zip -d /app

# 7. Download the dependencies
cd /app
npm install

# 8. Set up SystemD User Service
cat <<EOF > /etc/systemd/system/user.service
[Unit]
Description=User Service

[Service]
User=roboshop
Environment=MONGO=true
Environment=REDIS_HOST=$REDIS_SERVER_IP
Environment=MONGO_URL="mongodb://$MONGODB_SERVER_IP:27017/users"
ExecStart=/bin/node /app/server.js
SyslogIdentifier=user

[Install]
WantedBy=multi-user.target
EOF

# 9. Load the service, enable & start user
systemctl daemon-reload
systemctl enable user
systemctl start user

# 10. Set up MongoDB repo and install mongodb-client
cat <<EOF > /etc/yum.repos.d/mongo.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=0
enabled=1
EOF

dnf install -y mongodb-org-shell

# 11. Load Schema
mongo --host $MONGODB_SERVER_IP </app/schema/user.js

# 12. Reload the service
systemctl daemon-reload

