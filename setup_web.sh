#!/bin/bash

# 2. Install Nginx
echo "Installing Nginx..."
dnf install nginx -y
if [ $? -eq 0 ]; then
  echo "Nginx installed successfully"
else
  echo "Nginx installation failed"
  exit 1
fi

# 3. Start & Enable Nginx service
echo "Starting and enabling Nginx service..."
systemctl enable nginx
systemctl start nginx
if [ $? -eq 0 ]; then
  echo "Nginx service started and enabled successfully"
else
  echo "Failed to start or enable Nginx service"
  exit 1
fi

# 4. Remove the default content that web server is serving
echo "Removing default content..."
rm -rf /usr/share/nginx/html/*
if [ $? -eq 0 ]; then
  echo "Default content removed successfully"
else
  echo "Failed to remove default content"
  exit 1
fi

# 5. Download the frontend content
echo "Downloading frontend content..."
curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip
if [ $? -eq 0 ]; then
  echo "Frontend content downloaded successfully"
else
  echo "Failed to download frontend content"
  exit 1
fi

# 6. Extract the frontend content to /usr/share/nginx/html
echo "Extracting frontend content..."
unzip -o /tmp/web.zip -d /usr/share/nginx/html
if [ $? -eq 0 ]; then
  echo "Frontend content extracted successfully"
else
  echo "Failed to extract frontend content"
  exit 1
fi

# 7. Create Nginx Reverse Proxy Configuration
echo "Creating Nginx reverse proxy configuration..."
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
if [ $? -eq 0 ]; then
  echo "Nginx configuration file created successfully"
else
  echo "Failed to create Nginx configuration file"
  exit 1
fi

# 9. Restart Nginx Service to load the changes of the configuration
echo "Restarting Nginx service..."
systemctl restart nginx
if [ $? -eq 0 ]; then
  echo "Nginx service restarted successfully"
else
  echo "Failed to restart Nginx service"
  exit 1
fi

echo "Nginx setup completed successfully."

