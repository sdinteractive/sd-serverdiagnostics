#!/usr/bin/env bash

################################
# Pull in the configuration
################################
source '.env'

################################
# Functions
################################
# See: https://gist.github.com/cdown/1163649
urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

serverdiagnostic() {
    local diagnostic="$1"

    if [ -n "$2" ]; then
        if hash rpm 2>/dev/null; then
            diagnostic=$(rpm -q --queryformat '%{version}-%{release}' $diagnostic)
        elif hash dpkg-query 2>/dev/null; then
            diagnostic=$(dpkg-query -W -f='${Version}' $diagnostic)
        fi
    fi

    diagnostic=$(urlencode "$diagnostic" | tr '\n' ' ' | tr -d '"')

    echo $diagnostic
}

################################
# Prepare the post data
################################
# Name
if [ -z "$SD_MAGEDIAGNOSTICS_SERVER_NAME" ]; then
    name=$(hostname)
else
    name=$SD_MAGEDIAGNOSTICS_SERVER_NAME
fi
data="name=$(serverdiagnostic "$name")"

# Hostname
data="$data&hostname=$(serverdiagnostic "$(hostname)")"

# OS Version
osVersion=$(cat /etc/*-release | head -n 1)
data="$data&osVersion=$(serverdiagnostic "$osVersion")"

# cURL version
data="$data&curlVersion=$(serverdiagnostic curl 1)"

# Apache Version
if hash httpd 2>/dev/null; then
    data="$data&apacheVersion=$(serverdiagnostic httpd 1)"
fi

# Nginx Version
if hash nginx 2>/dev/null; then
    nginxVersion=$(nginx -v 2>&1 | tr '\n' ' ')
    data="$data&nginxVersion=$(serverdiagnostic nginx 1)"
fi

# OpenSSL version
openSslVersion=$(openssl version)
data="$data&openSslVersion=$(serverdiagnostic openssl 1)"


################################
# Execute the request
################################
curl -k -H "Authorization: Bearer $SD_MAGEDIAGNOSTICS_SERVER_KEY" --data "$data" $SD_MAGEDIAGNOSTICS_API_ENDPOINT
