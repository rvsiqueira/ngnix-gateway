#!/bin/bash
# Reload nginx configuration without downtime

set -e

echo "Testing nginx configuration..."
docker exec gateway-nginx nginx -t

if [ $? -eq 0 ]; then
    echo "Configuration valid. Reloading..."
    docker exec gateway-nginx nginx -s reload
    echo "Nginx reloaded successfully"
else
    echo "Configuration error! Not reloading."
    exit 1
fi
