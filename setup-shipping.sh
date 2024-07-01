#!/bin/bash

# 0. Create variables for IP addresses
CART_SERVER_IP="<cart.3gb.online>"
MYSQL_SERVER_IP="<mysql.3gb.online>"

# 1. Install Maven
dnf install maven -y

# 2. Add application user
useradd roboshop

# 3. Setup an app directory
mkdir /app

# 4. Download the application code to the created app directory & unzip
curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip
cd /app
unzip /tmp/shipping.zip

# 5. Download the dependencies at the app directory & build the application
cd /app
mvn clean package
mv target/shipping-1.0.jar shipping.jar

# 6. Setup SystemD Shipping Service
cat <<EOF > /etc/systemd/system/shipping.service
[Unit]
Description=Shipping Service

[Service]
User=roboshop
Environment=CART_ENDPOINT=${CART_SERVER_IP}:8080
Environment=DB_HOST=${MYSQL_SERVER_IP}
ExecStart=/bin/java -jar /app/shipping.jar
SyslogIdentifier=shipping

[Install]
WantedBy=multi-user.target
EOF

# 7. Load and start the service
systemctl daemon-reload

# 8. Enable and start the shipping service
systemctl enable shipping
systemctl start shipping

# 9. Install MySQL client
dnf install mysql -y

# 10. Load schema
mysql -h ${MYSQL_SERVER_IP} -uroot -pRoboShop@1 < /app/schema/shipping.sql

# 11. Restart the shipping service
systemctl restart shipping

