#!/bin/bash

# Tools
systemctl-exists() {
    [ $(systemctl list-unit-files "${1}*" | wc -l) -gt 3 ]
}
setLocalTime(){
    diff /etc/localtime /usr/share/zoneinfo/${1} || sudo ln -sf /usr/share/zoneinfo/${1} /etc/localtime
}
runCommand() {
    sudo $1 "${@:2}"
}

# SSM Agent
installSsmAgent() {
    if systemctl-exists *amazon-ssm-agent.service; then
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
    cd $PATH_APP
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

    cd $PATH_APP
}

# CodeDeploy Agent
installCodeDeployAgent() {
    if [ -f /opt/codedeploy-agent/bin/codedeploy-agent ]; then
        return
    fi

    sudo apt install ruby-full -y
    sudo apt install wget -y

    cd /home/ubuntu
    wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install
    sudo chmod +x ./install
    sudo ./install auto > /tmp/logfile

    cd $PATH_APP
}

# Install php
installPhp() {
    if [ -f /usr/bin/php ]; then
        return
    fi

    PHP_VERSION=$1
    PHP_EXT=$(echo $2 | tr "," "\n")

    runCommand apt install lsb-release ca-certificates apt-transport-https software-properties-common -y

    runCommand add-apt-repository ppa:ondrej/php -y

    runCommand apt -y update
    runCommand apt -y install php${PHP_VERSION}

    for EXT in $PHP_EXT
    do
        if [ $EXT == 'swoole' ]; then
            installSwoole $PHP_VERSION
        else
            runCommand apt -y install php${PHP_VERSION}-${EXT}
        fi
    done

    runCommand systemctl enable php${PHP_VERSION}-fpm.service

    # Configure php
    yes | runCommand cp -pr $PATH_APP/etc/php/* /etc/php/${PHP_VERSION}/fpm/pool.d/
}

# Install swoole
installSwoole(){
    PHP_VERSION=$1

    dpkg-query -l php8.1-openswoole > /dev/null

    if [ $? -eq 0 ]; then
        return
    fi

    runCommand add-apt-repository ppa:openswoole/ppa -y
    runCommand apt install -y php${PHP_VERSION}-openswoole
}

# Install Composer
installComposer() {
    if [ -f /usr/local/bin/composer ]; then
        return
    fi

    cd /tmp
    curl -sS https://getcomposer.org/installer | runCommand php
    runCommand mv composer.phar /usr/local/bin/composer
    cd $PATH_APP
}

# Install NGINX
installNginx() {
    sudo apt -y install nginx

    sudo systemctl enable nginx.service

    # Configure nginx
    yes | cp -pr $PATH_APP/etc/nginx/* /etc/nginx/

    sudo ln -s /etc/nginx/sites-available/* /etc/nginx/sites-enabled/
}

# Install Database
installDatabase() {
    DATABASE=mariadb

    sudo apt -y update
    sudo apt -y install ${DATABASE}-server ${DATABASE}-client

    sudo systemctl enable ${DATABASE}.service
}

# Install Git
installGit() {
    sudo apt -y install git
}

# Install Certbot
installCertbot() {
    if [ -f /usr/bin/certbot ]; then
        return
    fi

    sudo apt -y install certbot python3-certbot-nginx
}

# Install JQ
installJq() {
    if [ -f /usr/bin/jq ]; then
        return
    fi

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

    SWAP_SIZE=$1

    runCommand dd if=/dev/zero of=/swapfile1 bs=1024 count=${SWAP_SIZE}
    runCommand chmod 600 /swapfile1
    runCommand mkswap /swapfile1
    runCommand swapon /swapfile1
    echo "/swapfile1   none    swap    sw    0   0" | runCommand tee -a /etc/fstab
}

# Aws client
installAwsClient() {
    if [ -f /usr/local/bin/aws ]; then
        return
    fi

    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

# Supervisor
installSupervisor() {
    sudo apt install -y supervisor

    yes | cp -pr $PATH_APP/etc/supervisor/* /etc/supervisor/conf.d/

    supervisorctl update
}

installNode() {
    NODE_VERSION=$1

    if [ -z "$NODE_VERSION" ]; then
        NODE_VERSION="14"
    fi

    command -v nvm > /dev/null

    if [ $? -ne 0 ]; then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        echo "export NVM_DIR=\"$HOME/.nvm\"" >> "${PATH_ROOT}/.bashrc"
        echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"  # This loads nvm" >> "${PATH_ROOT}/.bashrc"
        echo "[ -s \"$NVM_DIR/bash_completion\" ] && \. \"$NVM_DIR/bash_completion\"  # This loads nvm bash_completion" >> "${PATH_ROOT}/.bashrc"
        source "${PATH_ROOT}/.bashrc"
        
        nvm install $NODE_VERSION
        nvm use $NODE_VERSION

        npm install --global yarn
    fi
}
