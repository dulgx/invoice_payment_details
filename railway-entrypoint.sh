#!/bin/bash
set -e

# Function to parse DATABASE_URL if individual vars are not set
parse_database_url() {
    if [ -n "$DATABASE_URL" ]; then
        echo "Parsing DATABASE_URL..."

        # Extract components using parameter expansion and sed
        # Format: postgresql://user:password@host:port/database

        # Remove the protocol part
        DB_URL_NO_PROTOCOL="${DATABASE_URL#postgresql://}"

        # Extract user and password
        DB_USER_PASS="${DB_URL_NO_PROTOCOL%%@*}"
        export DB_USER="${DB_USER_PASS%%:*}"
        export DB_PASSWORD="${DB_USER_PASS#*:}"

        # Extract host, port, and database
        DB_HOST_PORT_DB="${DB_URL_NO_PROTOCOL#*@}"
        DB_HOST_PORT="${DB_HOST_PORT_DB%%/*}"
        export DB_HOST="${DB_HOST_PORT%%:*}"
        export DB_PORT="${DB_HOST_PORT#*:}"
        export DB_NAME="${DB_HOST_PORT_DB#*/}"

        echo "Parsed database connection from DATABASE_URL"
        echo "DB_HOST: $DB_HOST"
        echo "DB_PORT: $DB_PORT"
        echo "DB_USER: $DB_USER"
        echo "DB_NAME: $DB_NAME"
    fi
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c '\q' 2>/dev/null; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
    done
    echo "PostgreSQL is up and running!"
}

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    echo "Checking if database '$DB_NAME' exists..."
    DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

    if [ "$DB_EXISTS" != "1" ]; then
        echo "Database '$DB_NAME' does not exist. Creating..."
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME"
        echo "Database '$DB_NAME' created successfully!"
    else
        echo "Database '$DB_NAME' already exists."
    fi
}

# Function to substitute environment variables in odoo.conf
substitute_env_vars() {
    echo "Substituting environment variables in odoo.conf..."

    # Create a temporary config file with substituted values
    cat /etc/odoo/odoo.conf | \
        sed "s/\${DB_HOST}/${DB_HOST}/g" | \
        sed "s/\${DB_PORT}/${DB_PORT}/g" | \
        sed "s/\${DB_USER}/${DB_USER}/g" | \
        sed "s/\${DB_PASSWORD}/${DB_PASSWORD}/g" | \
        sed "s/\${DB_NAME}/${DB_NAME}/g" | \
        sed "s/\${ADMIN_PASSWORD}/${ADMIN_PASSWORD}/g" \
        > /tmp/odoo.conf

    echo "Configuration file prepared!"
}

# Main execution
echo "Starting Odoo Railway Deployment..."
echo "=================================="

# Parse DATABASE_URL if provided (Railway standard)
parse_database_url

# Check required environment variables
REQUIRED_VARS=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME" "ADMIN_PASSWORD")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Required environment variable $var is not set!"
        exit 1
    fi
done

# Wait for PostgreSQL
wait_for_postgres

# Create database if it doesn't exist
create_database_if_not_exists

# Substitute environment variables in config
substitute_env_vars

# Check if we need to initialize/update the database
if [ "$INIT_DB" = "true" ]; then
    echo "Initializing Odoo database with invoice_payment_details module..."
    /usr/bin/odoo -c /tmp/odoo.conf -i invoice_payment_details --stop-after-init
fi

if [ "$UPDATE_MODULE" = "true" ]; then
    echo "Updating invoice_payment_details module..."
    /usr/bin/odoo -c /tmp/odoo.conf -u invoice_payment_details --stop-after-init
fi

# Start Odoo
echo "Starting Odoo server..."
echo "=================================="
exec /usr/bin/odoo -c /tmp/odoo.conf
