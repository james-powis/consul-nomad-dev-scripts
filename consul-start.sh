#!/usr/bin/env bash

# Set target environment variables for advertisement
my_int=$1 || "en0" # en0 is the default nic on a mac, sorry linux users, patch welcomed
my_ip=`ifconfig $my_int | grep "inet " | awk '{print $2}'`

# Start Consul
sudo consul agent -dev -dns-port 53 -client=0.0.0.0 -advertise=$my_ip -bind=0.0.0.0
