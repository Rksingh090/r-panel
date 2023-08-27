#!/bin/bash

service_name="rpanel"

# important paths 
main_directory="/app/rpanel"
executable="/app/rpanel/rpanel"
web_directory="/app/rpanel/websites"
ssl_directory="/etc/nginx/ssl"

# GitHub Raw File
github_file_url="https://raw.githubusercontent.com/Rksingh090/r-panel/master/rpanel"

checkCurl() {
    if ! command -v curl > /dev/null 2>&1; then
        echo "Installing Curl...";
        apt install curl -y
        echo "";
    else
        echo "Curl Already Installed...";
        echo "";
    fi
}

    
# install docker if not installed
checkDocker(){
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
        echo "";
    else 
        echo "Docker already installed...";
        echo "";
    fi
}

# Check if Nginx is installed or not
checkNGINX(){
    if command -v nginx &>/dev/null; then
        echo "Nginx is already installed..."
        echo "";
    else
        # Update package lists and install Nginx
        sudo apt update
        sudo apt install nginx -y

        # Start and enable Nginx
        sudo systemctl start nginx
        sudo systemctl enable nginx

        echo "Nginx has been installed and started."
        echo "";
    fi

    if [ ! -d "$ssl_directory" ]; then

    # Create the directory
        echo "$ssl_directory does not exist. Creating it..."
        mkdir -p "$ssl_directory"
        echo "$ssl_directory created successfully."
        echo "";
    else
        echo "$ssl_directory directory already exists."
        echo "";
    fi
}

# check mongodb installed or not
checkMongoDB(){
    # # Check if MongoDB is already installed
    if ! command -v mongod &> /dev/null; then
        # Install MongoDB
        echo "MongoDB not found. Installing MongoDB..."

        #Install MongoDB on Ubuntu
        sudo apt-get install gnupg -y
        curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
        sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg \
        --dearmor

        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

        sudo apt-get update

        sudo apt-get install -y mongodb-org

        #Start mongoDB after reboot
        sudo systemctl enable mongod
        sudo systemctl start mongod
        echo "MongoDB installed successfully."
    fi
}

# check rpanel exists
checkPanelExist(){
    # Check if the directory exists
    if [ ! -d "$web_directory" ]; then
        # Create the directory
        echo "$web_directory does not exist. Creating it..."
        mkdir -p "$web_directory"
        echo "$web_directory created successfully."
    fi
}

# check if rpanel already exist, remove if yes 
checkRPanelPaths(){
    if [ -f "$executable" ]; then
        # The file exists, remove it
        echo "Rpanel exists. Removing..."
        echo ""
        rm "$executable"
    fi
}

downloadLatestRPanel(){
    echo "Downloading Rpanel...."
    
    # Download the file
    curl -o "$main_directory/rpanel" "$github_file_url" > /dev/null 2>&1 &

    pid=$!
    percentage=0

    echo -n "Downloading: "

    # change color to green 
    printf "\e[32m";

    while kill -0 $pid 2>/dev/null && [ $percentage -le 100 ]; do
        printf "\rDownloading: [%-50s] %d%%" "$([ $percentage -le 100 ] && printf '=%.0s' $(seq 1 $((percentage / 2))))" "$percentage"
        percentage=$((percentage + 1))
        sleep 0.1
    done

    # reset the color 
    printf "\e[0m";
    

    echo "";
    echo "Download Completed."
    echo "";

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "File downloaded successfully to $main_directory/rpanel";
        echo "";
    else
        echo "Failed to download the file from GitHub.";
        echo "";
    fi

    sleep 5
    sudo chmod +x /app/rpanel/rpanel
    
}

checkRpanelService(){
    if sudo systemctl is-enabled "$service_name" >/dev/null 2>&1; then
        echo "Service $service_name is enabled. Stopping and disabling..."
        echo "";
        # Stop the service
        sudo systemctl stop "$service_name" >/dev/null 2>&1;
        # Disable the service
        sudo systemctl disable "$service_name" >/dev/null 2>&1;
    fi
}

checkCurl
checkDocker
checkNGINX
checkPanelExist
checkRPanelPaths
checkRpanelService
downloadLatestRPanel




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

sudo systemctl enable rpanel >/dev/null 2>&1;

#Start rpanel service
sudo systemctl start rpanel >/dev/null 2>&1;

print_success_message() {
    local message="RPanel Installed, Great Job !!!"
    local author="Rishab Singh"
    local url="https://github.com/Rksingh090"

    local color_green="\e[32m"
    local color_reset="\e[0m"
    
    new_message=$(cat << "EOF"
            ▒█▀▀█ ▒█▀▀█ ▒█▀▀█ ▒█▄  █ ▒█▀▀▀ ▒█ 
            ▒█▄▄▀ ▒█▄▄█ ▒█▄▄█ ▒█ █ █ ▒█▀▀▀ ▒█ 
            ▒█  █ ▒█    ▒█  █ ▒█  ▀█ ▒█▄▄▄ ▒█▄▄█
EOF
)

    printf "${color_green}%s\n" "============================================================="
    echo ""
    printf "$new_message"
    echo ""
    echo ""
    printf "${color_green}%s\n"     "============================================================="
    printf "${color_green}\n"
    printf "${color_green}%s\n"     "            $message"
    printf "${color_green}\n"
    printf "${color_green}%s\n"     "            Author - $author"
    printf "${color_green}%s\n"     "            Github - $url"
    printf "${color_green}\n"
    printf "${color_green}%s\n"     "============================================================="
    printf "${color_green}%s\n"     "            Open Rpanel on http://localhost:9000"
    printf "${color_green}%s\n"     "============================================================="
    printf "${color_reset}\n"
}

# Call the function to print the success message
print_success_message