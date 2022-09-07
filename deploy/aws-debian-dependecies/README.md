# Usage
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