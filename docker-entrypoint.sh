#!/bin/bash
set -e

# Create local.json config file with overrides from environment variables
CONFIG_DIR="/etc/onlyoffice/documentserver"
mkdir -p "$CONFIG_DIR"

HAS_CONFIG=false
CONFIG_FILE="$CONFIG_DIR/local.json"

# If config file already exists, preserve it (don't overwrite)
if [ -f "$CONFIG_FILE" ]; then
    echo "Existing config file found, preserving it. Set FORCE_RECONFIG=1 to regenerate."
    if [ "$FORCE_RECONFIG" != "1" ]; then
        # Just create sdkjs-plugins and exit
        mkdir -p /var/www/onlyoffice/documentserver/sdkjs-plugins
        exec "$@"
    fi
fi

# Start building JSON
echo "{" > "$CONFIG_FILE"

# RabbitMQ configuration
RABBITMQ_URL="${RABBITMQ_URL:-${AMQP_URI}}"
if [ -n "$RABBITMQ_URL" ]; then
    echo "Configuring RabbitMQ URL from environment variable: $RABBITMQ_URL"
    echo "  \"rabbitmq\": {" >> "$CONFIG_FILE"
    echo "    \"url\": \"$RABBITMQ_URL\"" >> "$CONFIG_FILE"
    echo "  }," >> "$CONFIG_FILE"
    HAS_CONFIG=true
fi

# Database configuration
if [ -n "$DB_HOST" ] || [ -n "$DB_PORT" ] || [ -n "$DB_NAME" ] || [ -n "$DB_USER" ] || [ -n "$DB_PASS" ]; then
    echo "Configuring database from environment variables"
    echo "  DB_HOST=$DB_HOST, DB_PORT=$DB_PORT, DB_NAME=$DB_NAME, DB_USER=$DB_USER"
    
    if [ "$HAS_CONFIG" = true ]; then
        echo "," >> "$CONFIG_FILE"
    fi
    
    DB_TYPE="${DB_TYPE:-postgres}"
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-5432}"
    DB_NAME="${DB_NAME:-onlyoffice}"
    DB_USER="${DB_USER:-onlyoffice}"
    DB_PASS="${DB_PASS:-onlyoffice}"
    
    echo "  \"services\": {" >> "$CONFIG_FILE"
    echo "    \"CoAuthoring\": {" >> "$CONFIG_FILE"
    echo "      \"sql\": {" >> "$CONFIG_FILE"
    echo "        \"type\": \"$DB_TYPE\"," >> "$CONFIG_FILE"
    echo "        \"dbHost\": \"$DB_HOST\"," >> "$CONFIG_FILE"
    echo "        \"dbPort\": $DB_PORT," >> "$CONFIG_FILE"
    echo "        \"dbName\": \"$DB_NAME\"," >> "$CONFIG_FILE"
    echo "        \"dbUser\": \"$DB_USER\"," >> "$CONFIG_FILE"
    echo "        \"dbPass\": \"$DB_PASS\"" >> "$CONFIG_FILE"
    echo "      }" >> "$CONFIG_FILE"
    echo "    }" >> "$CONFIG_FILE"
    echo "  }" >> "$CONFIG_FILE"
    HAS_CONFIG=true
fi

# Close JSON
echo "}" >> "$CONFIG_FILE"

if [ "$HAS_CONFIG" = true ]; then
    echo "Created $CONFIG_FILE with configuration overrides"
    # Validate JSON format
    python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1 && echo "Configuration file is valid JSON" || echo "Warning: Configuration file may have JSON syntax issues"
fi

# Create sdkjs-plugins directory if it doesn't exist (to avoid warning)
mkdir -p /var/www/onlyoffice/documentserver/sdkjs-plugins

# Execute the main command
exec "$@"
