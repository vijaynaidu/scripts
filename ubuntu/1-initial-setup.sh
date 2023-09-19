#!/bin/bash
# This is a Bash script for setting up and configuring a Linux system.
# References:
# - https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04
# - https://docs.docker.com/engine/install/ubuntu/
# - https://github.com/docker/compose/tags


# Set non-interactive mode for package installations
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

display_usage() {
    echo "Usage: $0 ENABLE_MAIL DOCKER_NETWORK_NAME DOCKER_NETWORK_SUBNET [SMTP_USERNAME SMTP_PASSWORD SMTP_MAILHUB DAEMON_EMAIL]"
    echo "ENABLE_MAIL: 'true' to enable email notifications, 'false' to disable"
    echo "DOCKER_NETWORK_NAME: Name for the Docker network (required)"
    echo "DOCKER_NETWORK_SUBNET: Subnet for the Docker network (required)"
    echo "SMTP_USERNAME: SMTP username for sending emails (required if ENABLE_MAIL is 'true')"
    echo "SMTP_PASSWORD: SMTP password for sending emails (required if ENABLE_MAIL is 'true')"
    echo "SMTP_MAILHUB: SMTP mailhub for sending emails (required if ENABLE_MAIL is 'true')"
    echo "DAEMON_EMAIL: Email address to receive notifications (required if ENABLE_MAIL is 'true')"
}

# Check if all required arguments are provided
if [ $# -lt 1 ]; then
    display_usage
    exit 1
fi

if [ "$1" != "false" ]; then
    # Check if all required arguments are provided
    if [ $# -ne 7 ]; then
        display_usage
        exit 1
    fi
fi

if [ "$2" == "" ]; then
    display_usage
    echo "Provide a name for the Docker network."
    exit 1
fi

if [ "$3" == "" ]; then
    display_usage
    echo "Provide subnet for the Docker network."
    exit 1
fi

# Assign the arguments to variables
ENABLE_MAIL=$1
DOCKER_NETWORK_NAME=$2
DOCKER_NETWORK_SUBNET=$3
SMTP_USERNAME=$4
SMTP_PASSWORD=$5
SMTP_MAILHUB=$6
DAEMON_EMAIL=$7

# Generate a random log file name in the /tmp directory
LOG_FILE="/tmp/system_setup_$(date +'%Y%m%d%H%M%S').log"

# Function to execute a command and log its output
execute_and_log() {
    local command="$1"
    echo "Executing: $command"
    echo "-----------------------------------------------------" >> "$LOG_FILE"
    echo "Command: $command" >> "$LOG_FILE"
    echo "-----------------------------------------------------" >> "$LOG_FILE"
    eval export DEBIAN_FRONTEND=noninteractive && export DEBIAN_PRIORITY=critical && "$command" 2>&1 | tee -a "$LOG_FILE"
    echo "-----------------------------------------------------" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Function to send an email with the command output
send_email() {
    local subject="$1 - $(TZ="Asia/Kolkata" date +'%Y-%m-%d %H:%M:%S')"
    echo "Sending the command output via email..."
    cat "$LOG_FILE" | mail -s "$subject" -a "From: $SMTP_USERNAME" "$DAEMON_EMAIL"
    # Delete the log file after sending the email
    rm -f "$LOG_FILE"
}

# System Info
system_info() {
    echo "System Info:"
    echo "  OS: $(lsb_release -ds)"
    echo "  Kernel: $(uname -r)"
    echo "  CPU: $(lscpu | grep 'Model name' | awk -F ': ' '{print $2}')"
    echo "  RAM: $(free -h | awk '/^Mem/ {print $2}')"
    echo "  Disk: $(df -h | awk '$NF=="/"{print $2}')"
    echo "  IP: $(hostname -I | awk '{print $1}')"
    echo "  Public IP: $(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)"
    echo "  DNS: $(grep -E "^nameserver" /etc/resolv.conf | awk '{print $2}')"
    lscpu
    ip a
    lsblk
    lsblk -O -J
}

# Function to upgrade the system
upgrade_system() {
    echo "Updating and upgrading system..."
    sudo apt-get update -qq && sudo apt-get upgrade -y -qq
    sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
}

# Function to install essential packages
install_essentials() {
    echo "Installing essential packages..."
    sudo apt-get install -y -qq zip
    sudo apt-get install -y -qq unzip
    sudo apt-get install -y -qq lm-sensors
    sudo apt-get install -y -qq iptables
    sudo apt-get install -y -qq jq
    sudo apt-get install -y -qq nmap
    sudo apt-get install -y -qq build-essential libssl-dev libffi-dev python-dev python-pip
    sudo apt-get install -y -qq nano
    sudo apt-get install -y -qq curl
    sudo apt-get install -y -qq wget
    sudo apt-get install -y -qq ssmtp
    sudo apt-get install -y -qq mailutils
    sudo apt-get install -y -qq python3-venv
    sudo apt-get install -y -qq python3-pip
}

# Function to configure ssmtp for sending emails via SMTP
configure_ssmtp() {
    echo "Configuring ssmtp for SMTP..."
    # Check if ssmtp.conf exists and has values for FromLineOverride, root, and mailhub
    if [ ! -f /etc/ssmtp/ssmtp.conf ] || ! grep -qE "^AuthUser=" /etc/ssmtp/ssmtp.conf; then
        # Replace placeholders with configurable values
        sudo tee /etc/ssmtp/ssmtp.conf > /dev/null <<EOF
UseTLS=YES
AuthMethod=LOGIN
FromLineOverride=YES
root=$SMTP_USERNAME
mailhub=$SMTP_MAILHUB
AuthUser=$SMTP_USERNAME
AuthPass=$SMTP_PASSWORD
EOF
    else
        echo "ssmtp.conf already exists with values for FromLineOverride, root, and mailhub. Skipping configuration."
    fi
}


# Function to send a test email using 'mail' command
send_test_email() {
    echo "Sending a test email..."
    echo "This is a test email sent from your Linux system." | mail -s "Test Email" -a "From: $SMTP_USERNAME" $DAEMON_EMAIL
}

# Function to install Docker if not already installed
install_docker() {
    if ! command -v docker &>/dev/null; then
        echo "Installing Docker..."
        
        # Add Docker's official GPG key
        sudo apt-get update -qq
        sudo apt-get install -y -qq ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the Docker repository to Apt sources
        echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -qq

        # Install Docker packages
        export NEEDRESTART_MODE=a && export DEBIAN_FRONTEND=noninteractive && export DEBIAN_PRIORITY=critical && sudo apt-get install -y -qq   -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" docker-ce docker-ce-cli containerd.io docker-buildx-plugin

        # Add the current user to the Docker group
        sudo usermod -aG docker $USER
    else
        echo "Docker is already installed."
    fi
}

# Function to install Docker Compose if not already installed
install_docker_compose() {
    if ! command -v docker-compose &>/dev/null; then
        echo "Installing Docker Compose..."

        # Install Docker Compose by fetching the latest release from GitHub API
        DOCKER_COMPOSE_LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/tags | jq -r '.[0].name')
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker-compose --version
    else
        echo "Docker Compose is already installed."
    fi
}

# Function to set the system timezone to UTC
set_timezone_utc() {
    echo "Setting system timezone to UTC..."
    sudo apt-get install -y -qq tzdata
    echo "Etc/UTC" | sudo tee /etc/timezone
    sudo dpkg-reconfigure --frontend noninteractive tzdata
}

# Function to create a Docker network
create_docker_network() {
    if ! docker network inspect $DOCKER_NETWORK_NAME &>/dev/null; then
        echo "Creating Docker network: $DOCKER_NETWORK_NAME"
        sudo docker network create --subnet=$DOCKER_NETWORK_SUBNET $DOCKER_NETWORK_NAME
    else
        echo "Docker network $DOCKER_NETWORK_NAME already exists. Skipping creation."
    fi
}

# Invoke the functions

execute_and_log "system_info"
execute_and_log "upgrade_system"
execute_and_log "install_essentials"

if [ "$ENABLE_MAIL" == "true" ]; then
    # Configure ssmtp
    execute_and_log "configure_ssmtp"

    # Send a test email
    # execute_and_log "send_test_email"
fi


execute_and_log "install_docker"
execute_and_log "install_docker_compose"
execute_and_log "set_timezone_utc"
execute_and_log "create_docker_network"

if [ "$ENABLE_MAIL" == "true" ]; then
    # Send the command output via email
    send_email "System Setup Log"
fi

echo "Setup completed."
