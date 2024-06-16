#!/bin/bash

# Define log file
LOG_FILE="user_service_setup_log.txt"

# Redis and MongoDB server IP address variables
REDIS_SERVER_IP="<REDIS-SERVER-IP>"
MONGODB_SERVER_IP="<MONGODB-SERVER-IP-ADDRESS>"

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
if ! dnf module list nodejs | grep -q '^nodejs\s\+18'; then
    perform_action "dnf module disable nodejs -y" "Disabling Node.js module"
    perform_action "dnf module enable nodejs:18 -y" "Enabling Node.js 18 module"
else
    log_message "Node.js 18 module already enabled"
fi

if ! node -v | grep -q 'v18'; then
    perform_action "dnf install nodejs -y" "Installing Node.js"
else
    log_message "Node.js already installed"
fi

# Add user and create application directory
if ! id "roboshop" &>/dev/null; then
    perform_action "useradd roboshop" "Creating user roboshop"
else
    log_message "User roboshop already exists"
fi

if [ ! -d /app ]; then
    perform_action "mkdir -p /app" "Creating /app directory"
else
    log_message "/app directory already exists"
fi

# Download and unzip the application
if [ ! -f /tmp/user.zip ]; then
    perform_action "curl -L -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip" "Downloading user application"
else
    log_message "User application already downloaded"
fi

if [ ! -d /app/node_modules ]; then
    perform_action "cd /app && unzip /tmp/user.zip && npm install" "Unzipping and installing user application"
else
    log_message "User application already unzipped and dependencies installed"
fi

# Create systemd service file for the user service
if [ ! -f /etc/systemd/system/user.service ]; then
    log_message "Creating systemd service file for user"
    cat <<EOL > /etc/systemd/system/user.service
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
EOL
    check_status $? "User service file creation"
else
    log_message "User service file already exists"
fi

# Enable and start the user service
perform_action "systemctl daemon-reload" "Reloading systemd daemon"
perform_action "systemctl enable user" "Enabling user service"
perform_action "systemctl start user" "Starting user service"

# Create MongoDB repo file
if [ ! -f /etc/yum.repos.d/mongo.repo ]; then
    log_message "Creating MongoDB repository file"
    cat <<EOL > /etc/yum.repos.d/mongo.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=0
enabled=1
EOL
    check_status $? "MongoDB repository file creation"
else
    log_message "MongoDB repository file already exists"
fi

# Install MongoDB shell
if ! rpm -q mongodb-org-shell &>/dev/null; then
    perform_action "dnf install mongodb-org-shell -y" "Installing MongoDB shell"
else
    log_message "MongoDB shell already installed"
fi

# Run MongoDB schema setup
perform_action "mongo --host $MONGODB_SERVER_IP </app/schema/user.js" "Setting up MongoDB schema"

log_message "Script finished"

