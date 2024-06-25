#!/bin/bash

# Step 1: Install remi-release rpm
echo "Installing remi-release rpm..."
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y

# Step 2: Enable Redis 6.2 from package streams
echo "Enabling Redis 6.2 from package streams..."
dnf module enable redis:remi-6.2 -y

# Step 3: Install Redis
echo "Installing Redis..."
dnf install redis -y

# Step 4: Update listen address from 127.0.0.1 to 0.0.0.0 in redis configuration files
echo "Updating listen address to 0.0.0.0..."
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf

# Step 5: Start & Enable Redis Service
echo "Starting and enabling Redis service..."
systemctl enable redis
systemctl start redis

echo "Redis installation and configuration completed successfully."

