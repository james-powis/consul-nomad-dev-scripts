#!/usr/bin/env bash

# Set target environment variables for advertisement
my_int=$1 || "en0" # en0 is the default nic on a mac, sorry linux users, patches welcome

# Start Nomad (In another shell, make sure to export the variables at the top)
nomad agent --dev -network-interface=$my_int
