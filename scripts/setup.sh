#!/bin/bash
# Setup script for gateway - run once on the server

set -e

echo "=== Gateway Setup ==="

# Create shared network if it doesn't exist
if ! docker network ls | grep -q shared-services; then
    echo "Creating shared-services network..."
    docker network create shared-services
    echo "Network created successfully"
else
    echo "Network shared-services already exists"
fi

# Create logs directory
mkdir -p ../logs

# Check SSL certificates
if [ ! -f "../nginx/ssl/fullchain.pem" ] || [ ! -f "../nginx/ssl/privkey.pem" ]; then
    echo ""
    echo "WARNING: SSL certificates not found!"
    echo "Please copy your SSL certificates to:"
    echo "  - gateway/nginx/ssl/fullchain.pem"
    echo "  - gateway/nginx/ssl/privkey.pem"
    echo ""
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy SSL certificates to nginx/ssl/"
echo "2. Start gateway: docker-compose up -d"
echo "3. Start other services in their respective directories"
