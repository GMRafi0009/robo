#!/bin/bash

# Define log file
LOG_FILE="nginx_setup_log.txt"

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

# Install Nginx
perform_action "dnf install nginx -y" "Installing Nginx"

# Enable and start Nginx service
perform_action "systemctl enable nginx" "Enabling Nginx service"
perform_action "systemctl start nginx" "Starting Nginx service"

# Remove existing HTML files
perform_action "rm -rf /usr/share/nginx/html/*" "Removing existing HTML files"

# Download and unzip the web application
perform_action "curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip" "Downloading web application"
perform_action "cd /usr/share/nginx/html && unzip /tmp/web.zip" "Unzipping web application"

# Create Nginx configuration file for Roboshop
log_message "Creating Nginx configuration file for Roboshop"
cat <<EOL > /etc/nginx/default.d/roboshop.conf
proxy_http_version 1.1;
location /images/ {
  expires 5s;
  root   /usr/share/nginx/html;
  try_files \$uri /images/placeholder.jpg;
}
location /api/catalogue/ { proxy_pass http://catalogue.3gb.online:8080/; }
location /api/user/ { proxy_pass http://user.3gb.online:8080/; }
location /api/cart/ { proxy_pass http://cart.3gb.online:8080/; }
location /api/shipping/ { proxy_pass http://localhost:8080/; }
location /api/payment/ { proxy_pass http://localhost:8080/; }

location /health {
  stub_status on;
  access_log off;
}
EOL
check_status $? "Creating Nginx configuration file"

# Restart Nginx to apply the new configuration
perform_action "systemctl restart nginx" "Restarting Nginx service"

log_message "Script finished"

