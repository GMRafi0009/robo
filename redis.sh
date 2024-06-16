#!/bin/bash

# Define log file
LOG_FILE="redis_setup_log.txt"

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

# Install Remi repository and Redis
perform_action "dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y" "Installing Remi repository"
perform_action "dnf module enable redis:remi-6.2 -y" "Enabling Redis 6.2 module"
perform_action "dnf install redis -y" "Installing Redis"

# Update Redis listen address
log_message "Updating Redis configuration to listen on all addresses"
sed -i 's/^bind 127.0.0.1$/bind 0.0.0.0/' /etc/redis.conf
sed -i 's/^bind 127.0.0.1$/bind 0.0.0.0/' /etc/redis/redis.conf
check_status $? "Updating Redis listen address"

# Enable and start Redis service
perform_action "systemctl enable redis" "Enabling Redis service"
perform_action "systemctl start redis" "Starting Redis service"

log_message "Script finished"

