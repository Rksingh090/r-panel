#!/bin/bash

apt update -y 
apt upgrade -y 

apt install curl -y


# install install 
if ! command -v docker &>/dev/null; then
    echo "Docker not installed. Installing Docker..."

    # Install Docker using the official Docker installation script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    # Add the current user to the 'docker' group to use Docker without sudo (you may need to log out and log back in for this to take effect)
    usermod -aG docker $USER

    # Start the Docker daemon
    systemctl start docker

    echo "Docker installed successfully."
else 
    echo "Docker already installed...";
fi


# # Check if MongoDB is already installed
# if ! command -v mongod &> /dev/null; then
#     # Install MongoDB
#     echo "MongoDB not found. Installing MongoDB..."

#     #Install MongoDB on Ubuntu
#     sudo apt-get install gnupg -y
#     curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
#     sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg \
#     --dearmor

#     echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

#     sudo apt-get update

#     sudo apt-get install -y mongodb-org

#     #Start mongoDB after reboot
#     sudo systemctl enable mongod
#     sudo systemctl start mongod
#     echo "MongoDB installed successfully."
# fi

main_directory="/app/rpanel"

# Check if the directory exists
if [ ! -d "$main_directory" ]; then
    # Create the directory
    echo "$main_directory does not exist. Creating it..."
    mkdir -p "$main_directory"
    echo "$main_directory created successfully."
fi


web_directory="/app/rpanel/websites"
# Check if the directory exists
if [ ! -d "$web_directory" ]; then
    # Create the directory
    echo "$web_directory does not exist. Creating it..."
    mkdir -p "$web_directory"
    echo "$web_directory created successfully."
fi



# Set the URL of the file on GitHub
github_file_url="https://raw.githubusercontent.com/Rksingh090/r-panel/master/rpanel"

# Set the target directory
target_directory="/app/rpanel"

file_to_check="/app/rpanel/rpanel"

if [ -f "$file_to_check" ]; then
    # The file exists, remove it
    echo "Rpanel exists. Removing..."
    rm "$file_to_check"
fi


# Download the file using curl
curl -fsSL -o "$target_directory/rpanel" "$github_file_url"

# Check if the download was successful
if [ $? -eq 0 ]; then
    echo "File downloaded successfully to $target_directory/rpanel"
else
    echo "Failed to download the file from GitHub."
fi

sudo chmod +x /app/rpanel/rpanel

service_name="rpanel"

if sudo systemctl is-enabled "$service_name" >/dev/null 2>&1; then
    echo "Service $service_name is enabled. Stopping and disabling..."
    # Stop the service
    sudo systemctl stop "$service_name"
    # Disable the service
    sudo systemctl disable "$service_name"
fi

sudo cat > /etc/systemd/system/rpanel.service <<EOF
[Unit]
Description=RPanel - Docker Deployment Made easy

[Service]
Type=simple
Restart=always
RestartSec=5s
ExecStart=/app/rpanel/rpanel

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable rpanel

#Start dauqu service
sudo systemctl start rpanel

echo "RPanel started successfully...";