# Scripts
This repository contains various scripts to automate the tasks.

## Ubuntu
### Initial Setup `ubuntu/initial-setup.sh`
This script will install the essentials and docker on Ubuntu.
#### Usage
- Download the script using command `curl https://raw.githubusercontent.com/vijaynaidu/scripts/main/ubuntu/initial-setup.sh -o initial-setup.sh`
```
Usage: 
initial-setup.sh ENABLE_MAIL DOCKER_NETWORK_NAME DOCKER_NETWORK_SUBNET [SMTP_USERNAME SMTP_PASSWORD SMTP_MAILHUB DAEMON_EMAIL]
ENABLE_MAIL: 'true' to enable email notifications, 'false' to disable
DOCKER_NETWORK_NAME: Name for the Docker network (required)
DOCKER_NETWORK_SUBNET: Subnet for the Docker network (required)
SMTP_USERNAME: SMTP username for sending emails (required if ENABLE_MAIL is 'true')
SMTP_PASSWORD: SMTP password for sending emails (required if ENABLE_MAIL is 'true')
SMTP_MAILHUB: SMTP mailhub for sending emails (required if ENABLE_MAIL is 'true')
DAEMON_EMAIL: Email address to receive notifications (required if ENABLE_MAIL is 'true')
```
- Command to initiate script (Examples): 
    - `sudo bash initial-setup.sh true "your_docker_network_name" "172.16.0.0/24" "noreply@example.com" "abcdpassword" "smtp.example.com:465" "daemon@example.com"`    
    - `sudo bash initial-setup.sh false "your_docker_network_name" "172.16.0.0/24"`


