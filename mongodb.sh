#!/bin/bash

# Define log file
LOG_FILE="script_log.txt"

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

# Install MongoDB and manage the service
perform_action "dnf install mongodb-org -y" "MongoDB installation"
perform_action "systemctl enable mongod" "MongoDB service enabling"
perform_action "systemctl start mongod" "MongoDB service starting"

# Update MongoDB configuration and restart the service
log_message "Updating MongoDB configuration to listen on all addresses"
sed -i 's/^  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/' /etc/mongod.conf
check_status $? "MongoDB configuration update"
perform_action "systemctl restart mongod" "MongoDB service restarting"

log_message "Script finished"

