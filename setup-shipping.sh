#!/bin/bash

# Step 1: Assign variables for IP addresses
CART_SERVER_IP="cart.3gb.online"   # Replace with actual CART server IP
MYSQL_SERVER_IP="mysql.3gb.online"  # Replace with actual MySQL server IP

# Step 2: Install Maven
dnf install maven -y

# Step 3: Add roboshop user
useradd roboshop

# Step 4: Create application directory
mkdir /app

# Step 5: Download the application code
curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip

# Step 6: Navigate to the application directory
cd /app

# Step 7: Unzip the application code
unzip /tmp/shipping.zip

# Step 8: Navigate to the application directory (redundant, as already in /app)
cd /app

# Step 9: Build the application
mvn clean package

# Step 10: Move the built jar file
mv target/shipping-1.0.jar shipping.jar

# Step 11: Create the systemd service file for Shipping
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

# Step 13: Reload systemd manager configuration
systemctl daemon-reload

# Step 14: Enable the Shipping service
systemctl enable shipping

# Step 15: Start the Shipping service
systemctl start shipping

# Step 16: Install MySQL
dnf install mysql -y

# Step 17: Load the schema into MySQL
mysql -h ${MYSQL_SERVER_IP} -uroot -pRoboShop@1 < /app/schema/shipping.sql

# Step 18: Restart the Shipping service
systemctl restart shipping

echo "Setup completed successfully."

