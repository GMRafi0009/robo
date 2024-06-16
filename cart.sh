#!/bin/bash

# Define log file
LOG_FILE="cart_service_setup_log.txt"

# Redis and Catalogue server IP address variables
REDIS_SERVER_IP="redis.3gb.online"
CATALOGUE_SERVER_IP="catalogue.3gb.online"

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

# Install Node.js if not already installed
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
if [ ! -f /tmp/cart.zip ]; then
    perform_action "curl -L -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip" "Downloading cart application"
else
    log_message "Cart application already downloaded"
fi

if [ ! -d /app/node_modules ]; then
    perform_action "cd /app && unzip /tmp/cart.zip && npm install" "Unzipping and installing cart application"
else
    log_message "Cart application already unzipped and dependencies installed"
fi

# Create systemd service file for the cart service
if [ ! -f /etc/systemd/system/cart.service ]; then
    log_message "Creating systemd service file for cart"
    cat <<EOL > /etc/systemd/system/cart.service
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
EOL
    check_status $? "Cart service file creation"
else
    log_message "Cart service file already exists"
fi

# Enable and start the cart service
perform_action "systemctl daemon-reload" "Reloading systemd daemon"
perform_action "systemctl enable cart" "Enabling cart service"
perform_action "systemctl start cart" "Starting cart service"

log_message "Script finished"

