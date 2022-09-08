#!/bin/bash

# Tools
systemctl-exists() {
    [ $(systemctl list-unit-files "${1}*" | wc -l) -gt 3 ]
}
setLocalTime(){
    diff /etc/localtime /usr/share/zoneinfo/${1} || sudo ln -sf /usr/share/zoneinfo/${1} /etc/localtime
}

# SSM Agent
installSsmAgent() {
    if systemctl-exists amazon-ssm-agent.service; then
        return
    fi
    
    cd /tmp
    if uname -m | grep -q aarch; then
        wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm64/amazon-ssm-agent.deb
    else
        wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    fi    
    sudo dpkg -i amazon-ssm-agent.deb
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
    cd ~/
}

# CloudWatch Agent
installCloudWatchAgent() {
    if systemctl-exists amazon-cloudwatch-agent.service; then
        return
    fi
    
    sudo apt -y update
    sudo apt -y install unzip
    
    mkdir /tmp/cwa
    cd /tmp/cwa
    if uname -m | grep -q aarch; then
        wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/arm64/latest/AmazonCloudWatchAgent.zip
    else
        wget https://s3.amazonaws.com/amazoncloudwatch-agent/linux/amd64/latest/AmazonCloudWatchAgent.zip
    fi  
    unzip AmazonCloudWatchAgent.zip
    sudo ./install.sh
    sudo mkdir /usr/share/collectd
    sudo touch /usr/share/collectd/types.db
}

# Install php
installPhp() {
    PHP_VERSION=$1
    PHP_EXT=$2
    
    if [ ! -z $PHP_VERSION ]; then
        return
    fi    

    sudo apt install lsb-release ca-certificates apt-transport-https software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php
    
    sudo apt -y update
    sudo apt -y install php${PHP_VERSION}
    
    if [ -z $PHP_EXT ]; then
        sudo apt -y install php${PHP_VERSION}-${PHP_EXT}
    fi
    
    sudo systemctl enable php${PHP_VERSION}-fpm.service
    
    # Configure php
    yes | cp -pr $PATH_APP/etc/php/* /etc/php/${PHP_VERSION}/fpm/pool.d/
    
    # Swoole
    apt install -y software-properties-common && add-apt-repository ppa:ondrej/php -y
    apt install -y software-properties-common && add-apt-repository ppa:openswoole/ppa -y
    
    apt install -y php${PHP_VERSION}-openswoole
}

# Install Composer
installComposer() {
    if [ -f /usr/local/bin/composer ]; then
        return
    fi
    
    cd /tmp
    curl -sS https://getcomposer.org/installer | sudo php
    sudo mv composer.phar /usr/local/bin/composer
    cd ~/
}

# Install NGINX
installNginx() {
    sudo apt -y update
    sudo apt -y install nginx
    
    sudo systemctl enable nginx.service
    
    # Configure nginx
    yes | cp -pr $PATH_APP/etc/nginx/* /etc/nginx/
}

# Install Database
installDatabase() {
    DATABASE=$1
    
    sudo apt -y update
    sudo apt -y install ${DATABASE}-server ${DATABASE}-client
    
    sudo systemctl enable ${DATABASE}.service
}

# Install Git
installGit() {
    sudo apt -y update
    sudo apt -y install git
}

# Install Certbot
installCertbot() {
    if [ -f /usr/bin/certbot ]; then
        return
    fi
    
    sudo apt -y update
    sudo apt -y install software-properties-common
    sudo add-apt-repository -y ppa:certbot/certbot
    sudo apt -y update
    sudo apt -y install certbot
}

# Install JQ
installJq() {
    if [ -f /usr/bin/jq ]; then
        return
    fi
    
    sudo apt -y update
    sudo apt -y install jq
}

# Generate Swap File
generateSwapFile() {
    if [ -f /swapfile1 ]; then
        return
    fi
    
    if [ -z $1 ]; then
        return
    fi
    
    sudo dd if=/dev/zero of=/swapfile1 bs=1024 count=${SWAP_SIZE}
    sudo chmod 600 /swapfile1
    sudo mkswap /swapfile1
    sudo swapon /swapfile1
    echo "/swapfile1   none    swap    sw    0   0" | sudo tee -a /etc/fstab
}