#!/bin/bash
# Frontend EC2 instance setup script for Nginx on Amazon Linux 2

# Update system
sudo yum update -y

# Install Nginx
sudo yum install nginx -y

# Create application directory
sudo mkdir -p /usr/share/nginx/html/myapp

# Create a script to generate the Nginx config with environment variables
cat > /etc/nginx/conf.d/generate-env-config.sh << 'EOL'
#!/bin/bash

# Update the myapp.conf file with current environment variables
sed -i "s|\\\${BACKEND_URL}|${BACKEND_URL}|g" /etc/nginx/conf.d/myapp.conf
sed -i "s|\\\${ENVIRONMENT}|${ENVIRONMENT}|g" /etc/nginx/conf.d/myapp.conf
sed -i "s|\\\${APP_VERSION}|${APP_VERSION}|g" /etc/nginx/conf.d/myapp.conf

# Also update the env-config.js file
cat > /usr/share/nginx/html/myapp/env-config.js << EOF
{
  "ENVIRONMENT": "${ENVIRONMENT}",
  "APP_VERSION": "${APP_VERSION}"
}
EOF
EOL

# Make the script executable
sudo chmod +x /etc/nginx/conf.d/generate-env-config.sh

# Set up a service to run the script on startup
cat > /etc/systemd/system/nginx-env-setup.service << EOL
[Unit]
Description=Generate Nginx environment configuration
Before=nginx.service

[Service]
Type=oneshot
ExecStart=/etc/nginx/conf.d/generate-env-config.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl enable nginx-env-setup.service

# Create index.html file
cat > /usr/share/nginx/html/myapp/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>4-Tier Application Demo</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <h1>4-Tier Application Demo</h1>
        <div class="info-box">
            <p>Environment: <span id="environment"></span></p>
            <p>Version: <span id="version"></span></p>
        </div>
        
        <div class="form-container">
            <h2>Add New Item</h2>
            <form id="addItemForm">
                <div class="form-group">
                    <label for="name">Name:</label>
                    <input type="text" id="name" name="name" required>
                </div>
                <div class="form-group">
                    <label for="description">Description:</label>
                    <textarea id="description" name="description" required></textarea>
                </div>
                <button type="submit" class="btn-submit">Submit</button>
            </form>
        </div>
        
        <div class="items-container">
            <h2>Items List</h2>
            <button id="refreshButton" class="btn-refresh">Refresh</button>
            <div id="itemsList"></div>
        </div>
        
        <div class="system-status">
            <h2>System Status</h2>
            <div class="status-grid">
                <div class="status-item">
                    <h3>Frontend</h3>
                    <div class="status-indicator online"></div>
                </div>
                <div class="status-item">
                    <h3>Backend</h3>
                    <div id="backendStatus" class="status-indicator checking"></div>
                </div>
                <div class="status-item">
                    <h3>Database</h3>
                    <div id="dbStatus" class="status-indicator checking"></div>
                </div>
                <div class="status-item">
                    <h3>Cache</h3>
                    <div id="cacheStatus" class="status-indicator checking"></div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Load environment variables from Nginx
        document.addEventListener('DOMContentLoaded', function() {
            // These would be populated by Nginx's variables
            fetch('/env-config.js')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('environment').textContent = data.ENVIRONMENT || 'Unknown';
                    document.getElementById('version').textContent = data.APP_VERSION || '1.0.0';
                })
                .catch(error => {
                    console.error('Error loading environment config:', error);
                });

            // Check system status
            checkBackendStatus();
            
            // Set up event listeners
            document.getElementById('refreshButton').addEventListener('click', fetchItems);
            document.getElementById('addItemForm').addEventListener('submit', addItem);
            
            // Load items on page load
            fetchItems();
        });

        function checkBackendStatus() {
            fetch('/api/health')
                .then(response => {
                    if (response.ok) {
                        document.getElementById('backendStatus').className = 'status-indicator online';
                        return response.json();
                    }
                    throw new Error('Backend unavailable');
                })
                .then(data => {
                    document.getElementById('dbStatus').className = 
                        data.database ? 'status-indicator online' : 'status-indicator offline';
                    document.getElementById('cacheStatus').className = 
                        data.cache ? 'status-indicator online' : 'status-indicator offline';
                })
                .catch(() => {
                    document.getElementById('backendStatus').className = 'status-indicator offline';
                    document.getElementById('dbStatus').className = 'status-indicator unknown';
                    document.getElementById('cacheStatus').className = 'status-indicator unknown';
                });
        }

        function fetchItems() {
            document.getElementById('itemsList').innerHTML = '<p>Loading...</p>';
            
            fetch('/api/items')
                .then(response => response.json())
                .then(items => {
                    const itemsList = document.getElementById('itemsList');
                    
                    if (items.length === 0) {
                        itemsList.innerHTML = '<p>No items found.</p>';
                        return;
                    }
                    
                    let html = '<ul class="items-list">';
                    items.forEach(item => {
                        html += `
                            <li class="item">
                                <h3>${item.name}</h3>
                                <p>${item.description}</p>
                                <div class="item-meta">
                                    <span>ID: ${item.id}</span>
                                    <span>Created: ${new Date(item.created_at).toLocaleString()}</span>
                                </div>
                                <button class="btn-delete" data-id="${item.id}">Delete</button>
                            </li>
                        `;
                    });
                    html += '</ul>';
                    
                    itemsList.innerHTML = html;
                    
                    // Add event listeners for delete buttons
                    document.querySelectorAll('.btn-delete').forEach(button => {
                        button.addEventListener('click', function() {
                            deleteItem(this.getAttribute('data-id'));
                        });
                    });
                })
                .catch(error => {
                    document.getElementById('itemsList').innerHTML = 
                        `<p class="error">Error loading items: ${error.message}</p>`;
                });
        }

        function addItem(event) {
            event.preventDefault();
            
            const nameInput = document.getElementById('name');
            const descriptionInput = document.getElementById('description');
            
            const item = {
                name: nameInput.value,
                description: descriptionInput.value
            };
            
            fetch('/api/items', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(item)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to add item');
                }
                return response.json();
            })
            .then(() => {
                // Reset form and refresh items list
                nameInput.value = '';
                descriptionInput.value = '';
                fetchItems();
                alert('Item added successfully!');
            })
            .catch(error => {
                alert(`Error: ${error.message}`);
            });
        }

        function deleteItem(id) {
            if (confirm('Are you sure you want to delete this item?')) {
                fetch(`/api/items/${id}`, {
                    method: 'DELETE'
                })
                .then(response => {
                    if (!response.ok) {
                        throw new Error('Failed to delete item');
                    }
                    fetchItems();
                    alert('Item deleted successfully!');
                })
                .catch(error => {
                    alert(`Error: ${error.message}`);
                });
            }
        }
    </script>
</body>
</html>
EOL

# Create styles.css file
cat > /usr/share/nginx/html/myapp/styles.css << 'EOL'
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
    background-color: #f4f4f4;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
}

h1, h2, h3 {
    margin-bottom: 15px;
}

h1 {
    text-align: center;
    margin-bottom: 30px;
    color: #2c3e50;
}

.info-box {
    background-color: #e3f2fd;
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 30px;
    border-left: 5px solid #2196f3;
}

.form-container, .items-container, .system-status {
    background-color: #fff;
    border-radius: 5px;
    padding: 20px;
    margin-bottom: 30px;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

.form-group {
    margin-bottom: 15px;
}

label {
    display: block;
    margin-bottom: 5px;
    font-weight: bold;
}

input, textarea {
    width: 100%;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 16px;
}

textarea {
    min-height: 100px;
    resize: vertical;
}

.btn-submit, .btn-refresh, .btn-delete {
    background-color: #4caf50;
    color: white;
    border: none;
    padding: 10px 15px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 16px;
    transition: background-color 0.3s;
}

.btn-refresh {
    background-color: #2196f3;
    margin-bottom: 15px;
}

.btn-delete {
    background-color: #f44336;
    padding: 5px 10px;
    font-size: 14px;
}

.btn-submit:hover, .btn-refresh:hover {
    background-color: #45a049;
}

.btn-refresh:hover {
    background-color: #0b7dda;
}

.btn-delete:hover {
    background-color: #d32f2f;
}

.items-list {
    list-style: none;
}

.item {
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 15px;
    margin-bottom: 15px;
}

.item-meta {
    display: flex;
    justify-content: space-between;
    color: #666;
    font-size: 14px;
    margin: 10px 0;
}

.error {
    color: #f44336;
    font-weight: bold;
}

.status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 15px;
    margin-top: 15px;
}

.status-item {
    text-align: center;
}

.status-indicator {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    margin: 10px auto;
}

.online {
    background-color: #4caf50;
}

.offline {
    background-color: #f44336;
}

.checking {
    background-color: #ff9800;
}

.unknown {
    background-color: #9e9e9e;
}

@media (max-width: 768px) {
    .status-grid {
        grid-template-columns: repeat(2, 1fr);
    }
}
EOL

# Create Nginx virtual host configuration
cat > /etc/nginx/conf.d/myapp.conf << 'EOL'
server {
    listen 80;
    server_name santosh.website;
    
    root /usr/share/nginx/html/myapp;
    index index.html;
    
    # Set environment variables directly in server context
    set $backend_url "${BACKEND_URL}";
    set $environment "${ENVIRONMENT}";
    set $app_version "${APP_VERSION}";
    
    # API requests forwarding to backend
    location /api {
        proxy_pass http://$backend_url:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Environment variables API endpoint
    location /env-config.js {
        default_type application/json;
        return 200 '{"ENVIRONMENT":"$environment", "APP_VERSION":"$app_version"}';
    }

    # Static content
    location / {
        try_files $uri $uri/ /index.html;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }

    # Error handling
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
    
    # Logging
    access_log /var/log/nginx/myapp-access.log;
    error_log /var/log/nginx/myapp-error.log;
}
EOL

# Set proper permissions
sudo chown -R nginx:nginx /usr/share/nginx/html/myapp
sudo chmod -R 755 /usr/share/nginx/html/myapp

# Set some initial environment variables if not already set
export BACKEND_URL=${BACKEND_URL:-"localhost"}
export ENVIRONMENT=${ENVIRONMENT:-"development"}
export APP_VERSION=${APP_VERSION:-"1.0.0"}

# Generate the initial config based on current environment variables
/etc/nginx/conf.d/generate-env-config.sh

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# Enable Nginx on boot
systemctl enable nginx

echo "Frontend setup with Nginx on Amazon Linux completed successfully!"