#!/bin/bash
# Template script for adding a new service to the gateway

SERVICE_NAME=$1
SERVICE_PORT=$2
SERVICE_PATH=$3

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_PORT" ] || [ -z "$SERVICE_PATH" ]; then
    echo "Usage: ./add-service.sh <service-name> <port> <path>"
    echo "Example: ./add-service.sh my-api 8080 /my-api"
    exit 1
fi

# Create upstream entry
cat >> ../nginx/conf.d/upstreams.conf << EOF

# $SERVICE_NAME
upstream $SERVICE_NAME {
    server $SERVICE_NAME:$SERVICE_PORT;
    keepalive 32;
}
EOF

# Create location config
cat > ../nginx/conf.d/locations/${SERVICE_NAME}.conf << EOF
# $SERVICE_NAME
location $SERVICE_PATH/ {
    rewrite ^${SERVICE_PATH}/(.*)$ /\$1 break;

    proxy_pass http://$SERVICE_NAME;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Connection "";
}
EOF

echo "Created configuration for $SERVICE_NAME"
echo ""
echo "Next steps:"
echo "1. Update your service's docker-compose.yml to:"
echo "   - Add container_name: $SERVICE_NAME"
echo "   - Add network: shared-services (external: true)"
echo "2. Reload nginx: ./reload-nginx.sh"
