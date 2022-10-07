#!/bin/bash

mysqlCreateDatabase() {
    if [ -z "$1" ]; then
        return 0
    fi

    DATABASE=$1

    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DATABASE};"

    if [ $? -ne 0 ]; then
        return 0
    fi

    return 1
}

mysqlCreateUser() {
    if [ -z "$2" ]; then
        return 0
    fi

    USER=$1
    PASSWORD=$2

    mysql -u root -e "CREATE USER IF NOT EXISTS '${USER}'@'localhost' IDENTIFIED BY '${PASSWORD}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    return 1
}