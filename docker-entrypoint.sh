#!/bin/bash
set -e

# Create local.json config file if RABBITMQ_URL is set
if [ -n "$RABBITMQ_URL" ]; then
    echo "Configuring RabbitMQ URL from environment variable: $RABBITMQ_URL"
    mkdir -p /etc/onlyoffice/documentserver
    cat > /etc/onlyoffice/documentserver/local.json <<EOF
{
  "rabbitmq": {
    "url": "$RABBITMQ_URL"
  }
}
EOF
    echo "Created /etc/onlyoffice/documentserver/local.json with RabbitMQ configuration"
fi

# Create sdkjs-plugins directory if it doesn't exist (to avoid warning)
mkdir -p /var/www/onlyoffice/documentserver/sdkjs-plugins

# Execute the main command
exec "$@"

