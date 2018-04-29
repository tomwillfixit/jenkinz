#!/bin/bash

# Simple script to test connectivity to memcached 
# Takes 1 arguments; the image names for memcached

if [ "$#" -ne 1 ]; then
    echo "Wrong number of parameters"
    exit 2
fi

memcached_image=$1
memcached_default_port=11211

echo "Starting Memcached"
docker run -d -p ${memcached_default_port}:${memcached_default_port} ${memcached_image}

echo "Verify connection to Memcached"
echo "This will timeout after 2 minutes and the test will fail"

end=$((SECONDS+120))

while [ $SECONDS -lt $end ]; do
    echo "stats" | nc 0.0.0.0 ${memcached_default_port} |grep uptime
    if [ $? -eq 0 ];then
        echo "Connection to Memcached succeeded"
	exit 0
    else
	echo "Waiting for connection to take place ..."
    fi
    sleep 5
done

exit 1

