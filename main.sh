#!/usr/bin/env bash

################################
# Pull in the configuration
################################
source '.env'

################################
# Prepare the post data
################################
# Name
if [ -z "$SD_MAGEDIAGNOSTICS_SERVER_NAME" ]; then
    name=$(hostname)
else
    name=$SD_MAGEDIAGNOSTICS_SERVER_NAME
fi
data="name=$name"

# Hostname
data="$data&hostname="$(hostname)

# OS Version
osVersion=$(cat /etc/*-release* | tr '\n' ' ' | tr -d '"')
data="$data&osVersion=$osVersion"

# cURL version
curlVersion=$(curl --version | tr '\n' ' ')
data="$data&curlVersion=$curlVersion"

# Apache Version
if hash httpd 2>/dev/null; then
    apacheVersion=$(httpd -v | tr '\n' ' ')
    data="$data&apacheVersion=$apacheVersion"
fi

# Nginx Version
if hash nginx 2>/dev/null; then
    nginxVersion=$(nginx -v 2>&1 | tr '\n' ' ')
    data="$data&nginxVersion=$nginxVersion"
fi

# OpenSSL version
openSslVersion=$(openssl version)
data="$data&openSslVersion=$openSslVersion"

################################
# Execute the request
################################
curl -k -H "Authorization: Bearer $SD_MAGEDIAGNOSTICS_SERVER_KEY" --data "$data" $SD_MAGEDIAGNOSTICS_API_ENDPOINT
