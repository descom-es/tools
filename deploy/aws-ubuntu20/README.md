# Usage

Documentation for deploy on Ubuntu 20.04 on amazon EC2

## User Data
```
#!/bin/bash
systemctl-exists() {
    [ $(systemctl list-unit-files "${1}*" | wc -l) -gt 3 ]
}
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

installSsmAgent
```

## Install CodeDeploy Agent
```
#!/bin/bash
sudo apt update
sudo apt install ruby-full
sudo apt install wget

cd /home/ubuntu
wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install

chmod +x ./install
sudo ./install auto > /tmp/logfile
```

## Example library usage
```
#!/bin/bash
. ./lib.sh

PATH_APP="$(dirname $0)/"

setLocalTime "Europe/Madrid"
sudo apt -y update
installSsmAgent
installCloudWatchAgent
installPhp 8.1 "fpm,mbstring,dom,gd,soap"
installComposer
installNginx
installDatabase "mariadb"
installGit
installCertbot
generateSwapFile 1048576 # 1GB

```