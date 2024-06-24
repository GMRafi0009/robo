#!/bin/bash

# 0. Create variable for MongoDB server IP address
MONGODB_SERVER_IPADDRESS="<MONGODB-SERVER-IPADDRESS>"

# Step 1: Install NodeJS
echo "Installing NodeJS..."
dnf install nodejs -y

# Step 2: Disable default NodeJS & enable NodeJS 18
echo "Disabling default NodeJS and enabling NodeJS 18..."
dnf module disable nodejs -y
dnf module enable nodejs:18 -y

# Step 3: Install NodeJS again to get version 18
echo "Installing NodeJS version 18..."
dnf install nodejs -y

# Step 4: Add application user
echo "Adding application user roboshop..."
useradd roboshop

# Step 5: Setup an app directory
echo "Creating /app directory..."
mkdir /app

# Step 6: Download the application code to the created app directory
echo "Downloading application code..."
curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip

# Step 7: Unzip the files in the location
echo "Unzipping application code..."
cd /app
unzip /tmp/catalogue.zip

# Step 8: Download the dependencies
echo "Installing application dependencies..."
npm install 

# Step 9: Setup SystemD Catalogue Service
echo "Setting up SystemD Catalogue Service..."
cat <<EOL > /etc/systemd/system/catalogue.service
[Unit]
Description=Catalogue Service

[Service]
User=roboshop
Environment=MONGO=true
Environment=MONGO_URL="mongodb://$MONGODB_SERVER_IPADDRESS:27017/catalogue"
ExecStart=/bin/node /app/server.js
SyslogIdentifier=catalogue

[Install]
WantedBy=multi-user.target
EOL

# Step 10: Load the service
echo "Loading the catalogue service..."
systemctl daemon-reload

# Step 11: Enable & start the service
echo "Enabling and starting the catalogue service..."
systemctl enable catalogue
systemctl start catalogue

# Step 12: Setup MongoDB repo and install mongodb-client
echo "Setting up MongoDB repo..."
cat <<EOL > /etc/yum.repos.d/mongo.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=0
enabled=1
EOL

# Step 13: Install MongoDB client
echo "Installing MongoDB client..."
dnf install mongodb-org-shell -y

# Step 14: Load Schema
echo "Loading MongoDB schema..."
mongo --host $MONGODB_SERVER_IPADDRESS </app/schema/catalogue.js

echo "All tasks completed successfully."

