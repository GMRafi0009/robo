#!/bin/bash

# Define log file
LOG_FILE="script_log.txt"

# MongoDB server IP address variable
MONGODB_SERVER_IPADDRESS="<MONGODB-SERVER-IPADDRESS>"

# Function to log messages with date and time
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to check the status and print colored messages
check_status() {
    local status=$1
    local message=$2
    if [ $status -eq 0 ]; then
        echo -e "\e[32m$message - Success\e[0m" | tee -a "$LOG_FILE"
    else
        echo -e "\e[31m$message - Error\e[0m" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Check if the user is root
if [ "$(id -u)" -ne 0 ]; then
    log_message "Script must be run as root. Exiting."
    echo -e "\e[31mScript must be run as root. Exiting.\e[0m"
    exit 1
fi

log_message "Script started"

# Function to perform an action and log the result
perform_action() {
    local command=$1
    local message=$2
    eval "$command" &>> "$LOG_FILE"
    check_status $? "$message"
}

# Disable the default Node.js module and enable Node.js 18
perform_action "dnf module disable nodejs -y" "Disabling Node.js module"
perform_action "dnf module enable nodejs:18 -y" "Enabling Node.js 18 module"
perform_action "dnf install nodejs -y" "Installing Node.js"

# Add user and create application directory
perform_action "id -u roboshop &>/dev/null || useradd roboshop" "Creating user roboshop"
perform_action "mkdir -p /app" "Creating /app directory"

# Download and unzip the application
perform_action "curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip" "Downloading catalogue application"
perform_action "cd /app && unzip -o /tmp/catalogue.zip" "Unzipping catalogue application"
perform_action "cd /app && npm install" "Installing application dependencies"

# Create systemd service file for the catalogue service
log_message "Creating systemd service file for catalogue"
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
check_status $? "Catalogue service file creation"

# Enable and start the catalogue service
perform_action "systemctl daemon-reload" "Reloading systemd manager configuration"
perform_action "systemctl enable catalogue" "Enabling catalogue service"
perform_action "systemctl start catalogue" "Starting catalogue service"

# Create MongoDB repo file
log_message "Creating MongoDB repository file"
cat <<EOL > /etc/yum.repos.d/mongo.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=0
enabled=1
EOL
check_status $? "MongoDB repository file creation"

# Run MongoDB schema setup
log_message "Setting up MongoDB schema"
mongo --host $MONGODB_SERVER_IPADDRESS </app/schema/catalogue.js &>> "$LOG_FILE"
check_status $? "Setting up MongoDB schema"

log_message "Script finished"

