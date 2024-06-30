#!/bin/bash

# 0. Create variable for IP addresses
REDIS_SERVER_IP="redis.3gb.online"
CATALOGUE_SERVER_IP="catalogue.3gb.online"

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
curl -L -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip

# 6. Unzip the downloaded file to /app
unzip /tmp/cart.zip -d /app

# 7. Download the dependencies
cd /app
npm install

# 8. Set up SystemD Cart Service
cat <<EOF > /etc/systemd/system/cart.service
[Unit]
Description=Cart Service

[Service]
User=roboshop
Environment=REDIS_HOST=$REDIS_SERVER_IP
Environment=CATALOGUE_HOST=$CATALOGUE_SERVER_IP
Environment=CATALOGUE_PORT=8080
ExecStart=/bin/node /app/server.js
SyslogIdentifier=cart

[Install]
WantedBy=multi-user.target
EOF

# 9. Load the service, enable & start cart
systemctl daemon-reload
systemctl enable cart
systemctl start cart

