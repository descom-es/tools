# Usage

## User Data
Check [user data skeleton](./aws_userdata_skeleton.sh) script for usage

## Example library usage
```
#!/bin/bash
. ./lib.sh

PATH_APP="$(dirname $0)/"

setLocalTime "Europe/Madrid"
sudo apt -y update
installSsmAgent
installCloudWatchAgent
installPhp 8.1 "fpm,mbstring,dom,gd,soap,swoole"
installComposer
installNginx
installDatabase
installGit
installCertbot
generateSwapFile 1048576 # 1GB

```