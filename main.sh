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

# Used to get the value that will be sent as a server diagnostic
# You can send it 3 arguments:
#
# 1. The diagnostic your are looking up
# 2. Should we try to get the version information through a package manager?
# 3. Is this a file we are talking about
#
# It will run the value through a urlencode function before returning it
serverdiagnostic() {
    local diagnostic="$1"

    if [ -n "$2" ]; then
        if hash rpm 2>/dev/null; then
            if [ -n "$3" ]; then
                diagnostic=$(rpm -qf --queryformat '%{version}-%{release}' $diagnostic)
            else
                diagnostic=$(rpm -q --queryformat '%{version}-%{release}' $diagnostic)
            fi
        elif hash dpkg-query 2>/dev/null; then
            if [ -n "$3" ]; then
                diagnostic=$(dpkg-query -S $diagnostic | awk '{ print $1 }' | tr -d ':' | xargs dpkg-query -W -f='${Version}')
            else
                diagnostic=$(dpkg-query -W -f='${Version}' $diagnostic)
            fi
        fi
    fi

    diagnostic=$(urlencode "$diagnostic" | tr '\n' ' ' | tr -d '"')

    echo $diagnostic
}

fileSystemData() {
    result="{"
    result="$result$(df -Ph | grep -vE 'Filesystem' | awk '{print "\"" $1 "\": {\"Size\": \"" $2 "\", \"Used\": \"" $3 "\"},"}' | tr '\n' ' '| head -c-2)"
    result="$result}"

    echo $result
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

# Kernel Release
kernelRelease=$(uname -r)
data="$data&kernelRelease=$(serverdiagnostic "$kernelRelease")"

# File Systems
fileSystems=$(fileSystemData)
data="$data&fileSystems=$(serverdiagnostic "$fileSystems")"

# cURL version
data="$data&curlVersion=$(serverdiagnostic curl 1)"

# Apache Version
if hash httpd 2>/dev/null; then
    data="$data&apacheVersion=$(serverdiagnostic /usr/sbin/httpd 1 1)"
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
curl -k -H -s "Authorization: Bearer $SD_MAGEDIAGNOSTICS_SERVER_KEY" --data "$data" $SD_MAGEDIAGNOSTICS_API_ENDPOINT
