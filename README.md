# 4-tier-project

The status indicators are color-coded:

Green (online) - Component is working correctly
Red (offline) - Component is down
Orange (checking) - Status is being checked
Gray (unknown) - Status cannot be determined (typically when the backend is unavailable)



PM2_DB_HOST=database.cnwcymm6otu4.us-east-1.rds.amazonaws.com \
PM2_DB_USER=admin \
PM2_DB_PASSWORD=admin123 \
PM2_DB_NAME=project \
PM2_DB_PORT=3306 \
PM2_ENVIRONMENT=production \
PM2_APP_VERSION=1.0.0 \
PM2_REDIS_HOST=10.0.6.240 \
PM2_REDIS_PORT=6379 \
PM2_REDIS_PASSWORD=santosh \
pm2 restart backend --update-env

cat > .env << EOL
# Application settings
PORT=3000
ENVIRONMENT=production
APP_VERSION=1.0.0
NODE_ENV=production

# Database settings
DB_HOST=database.cnwcymm6otu4.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=admin123
DB_NAME=project

# Redis cache settings
REDIS_HOST=10.0.6.240
REDIS_PORT=6379
REDIS_PASSWORD=santosh

# Logging settings
LOG_LEVEL=info
EOL




curl http://localhost:3000/api/health

run in backend server



# Update backend URL
sudo sed -i 's/set $backend_url "${BACKEND_URL}";/set $backend_url "10.0.5.185";/g' /etc/nginx/conf.d/myapp.conf

# Update environment
sudo sed -i 's/set $environment "${ENVIRONMENT}";/set $environment "production";/g' /etc/nginx/conf.d/myapp.conf

# Update app version
sudo sed -i 's/set $app_version "${APP_VERSION}";/set $app_version "1.0.1";/g' /etc/nginx/conf.d/myapp.conf

# Restart Nginx to apply changes
sudo systemctl restart nginx


sudo -u redis redis-server /etc/redis/redis.conf --daemonize no

sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
sudo yum install  java-17-amazon-corretto-devel -y
sudo yum install jenkins -y
systemctl start jenkins
systemctl enable jenkins

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform
terraform version

yum install git -y

