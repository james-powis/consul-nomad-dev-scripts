#!/usr/bin/env bash

# Set target environment variables for advertisement
export MY_INTERFACE="en0" # Change this depending on your config
export MY_IP=`ifconfig $MY_INTERFACE | grep "inet " | awk '{print $2}'`

# Start Nomad (In another shell, make sure to export the variables at the top)
nomad agent --dev -network-interface=$MY_INTERFACE
