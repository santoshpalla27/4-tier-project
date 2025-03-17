#!/bin/bash
# Redis Cache EC2 instance setup script for Amazon Linux 2023

# Update system
sudo dnf update -y

# Install build dependencies
sudo dnf install -y gcc make wget systemd-devel

# Download and compile Redis (using latest stable version)
cd /tmp
wget https://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make

# Install binary files
sudo make install

# Create Redis user
sudo useradd --system --user-group --no-create-home redis

# Create necessary directories
sudo mkdir -p /etc/redis
sudo mkdir -p /var/lib/redis
sudo mkdir -p /var/log/redis
sudo chown redis:redis /var/lib/redis
sudo chown redis:redis /var/log/redis

# Copy and modify configuration
sudo cp redis.conf /etc/redis/
sudo sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
sudo sed -i 's/^dir \.\//dir \/var\/lib\/redis\//' /etc/redis/redis.conf
sudo sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sudo sed -i 's/# requirepass foobared/requirepass santosh/' /etc/redis/redis.conf
sudo sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
sudo sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
sudo sed -i 's/^logfile ""/logfile \/var\/log\/redis\/redis.log/' /etc/redis/redis.conf

# Create systemd service file
sudo cat > /etc/systemd/system/redis.service << EOL
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always
Type=notify
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=redis

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start Redis
sudo systemctl daemon-reload
sudo systemctl enable redis
sudo systemctl start redis

# Configure firewall (if using Amazon Linux's firewalld)
sudo firewall-cmd --permanent --add-port=6379/tcp
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

echo "Redis Cache setup on Amazon Linux 2023 completed successfully!"