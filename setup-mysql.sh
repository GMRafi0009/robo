#!/bin/bash

# 1. Disable MySQL 8 version
dnf module disable mysql -y

# 2. Setup the MySQL 5.7 repo file
cat <<EOF > /etc/yum.repos.d/mysql.repo
[mysql]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/\$basearch/
enabled=1
gpgcheck=0
EOF

# 3. Install MySQL Server
dnf install mysql-community-server -y

# 4. Enable and start MySQL Service
systemctl enable mysqld
systemctl start mysqld

# 5. Changing the default root password
mysql_secure_installation --set-root-pass RoboShop@1

# Verify MySQL service is running
systemctl status mysqld

