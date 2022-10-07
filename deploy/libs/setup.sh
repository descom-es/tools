#!/bin/bash

mysqlCreateDatabase() {
    if [ -z "$1" ]; then
        return false
    fi

    DATABASE=$1

    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DATABASE};"

    if [ $? -ne 0 ]; then
        return false
    fi

    return true
}

mysqlCreateUser() {
    if [ -z "$1" -o -z "$2" ]; then
        return false
    fi

    USER=$1
    PASSWORD=$2

    mysql -u root -e "CREATE USER IF NOT EXISTS '${USER}'@'localhost' IDENTIFIED BY '${PASSWORD}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
}