#!/bin/bash

mkdir -p /tmp/descom_install
cd /tmp/descom_install

wget https://raw.githubusercontent.com/descom-es/tools/master/deploy/libs/aws_install.sh
. ./aws_install.sh

setLocalTime "Europe/Madrid"
generateSwapFile 1048576 # 1GB
installSsmAgent
# installCloudWatchAgent
# install
# installPhp 8.1 "fpm,mbstring,dom,gd,soap,swoole"
# installComposer
# installNginx
# installDatabase
# installGit
# installCertbot