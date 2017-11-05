#!/usr/bin/env bash

# Set target environment variables for advertisement
export MY_INTERFACE="en0" # Change this depending on your config
export MY_IP=`ifconfig $MY_INTERFACE | grep "inet " | awk '{print $2}'`

# Start Consul
sudo consul agent -dev -dns-port 53 -client=0.0.0.0 -advertise=$MY_IP -bind=0.0.0.0
