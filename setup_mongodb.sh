#!/bin/bash

LOG_FILE="mongodb_setup.log"
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
USER_ID=$(id -u)
COLOR_GREEN="\e[32m"
COLOR_RED="\e[31m"
COLOR_YELLOW="\e[33m"
COLOR_RESET="\e[0m"

# Function to log messages with date and time
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check the status of the last executed command
check_status() {
  if [ $? -eq 0 ]; then
    log_message "SUCCESS: $1"
    echo -e "${COLOR_GREEN}SUCCESS: $1${COLOR_RESET}"
  else
    log_message "FAILURE: $1"
    echo -e "${COLOR_RED}FAILURE: $1${COLOR_RESET}"
    exit 1
  fi
}

# Log the start of the script
log_message "Script started by user ID: $USER_ID"
log_message "Script start time: $START_TIME"

# Check if the user is root
if [ "$USER_ID" -ne 0 ]; then
  log_message "FAILURE: Script must be run as root"
  echo -e "${COLOR_RED}FAILURE: Script must be run as root${COLOR_RESET}"
  exit 1
else
  log_message "User is root, proceeding with script execution"
fi

# 1. Setup the MongoDB repo file
log_message "Setting up the MongoDB repo file"
cat > /etc/yum.repos.d/mongo.repo <<EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.2/x86_64/
gpgcheck=0
enabled=1
EOF
check_status "Setup the MongoDB repo file"

# 2. Install MongoDB
log_message "Installing MongoDB"
dnf install mongodb-org -y &> /dev/null
check_status "Install MongoDB"

# 3. Start & Enable MongoDB Service
log_message "Enabling MongoDB Service"
systemctl enable mongod &> /dev/null
check_status "Enable MongoDB Service"

log_message "Starting MongoDB Service"
systemctl start mongod &> /dev/null
check_status "Start MongoDB Service"

# 4. Update listen address from 127.0.0.1 to 0.0.0.0 in /etc/mongod.conf
log_message "Updating mongod.conf listen address"
sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
check_status "Update listen address in mongod.conf"

# 5. Restart the service
log_message "Restarting MongoDB Service"
systemctl restart mongod &> /dev/null
check_status "Restart MongoDB Service"

# Log the end of the script
END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
log_message "Script end time: $END_TIME"
log_message "MongoDB setup completed successfully."
echo -e "${COLOR_GREEN}MongoDB setup completed successfully.${COLOR_RESET}"

