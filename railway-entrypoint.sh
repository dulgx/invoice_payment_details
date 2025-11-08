#!/bin/bash
set -e

# Function to parse DATABASE_URL
parse_database_url() {
    if [ -n "$DATABASE_URL" ] && [ -z "$DB_HOST" ]; then
        echo "Parsing DATABASE_URL..."

        # Remove postgresql:// prefix
        DB_URL_NO_PROTOCOL="${DATABASE_URL#postgresql://}"

        # Extract user:password
        DB_USER_PASS="${DB_URL_NO_PROTOCOL%%@*}"
        export DB_USER="${DB_USER_PASS%%:*}"
        export DB_PASSWORD="${DB_USER_PASS#*:}"

        # Extract host:port/database
        DB_HOST_PORT_DB="${DB_URL_NO_PROTOCOL#*@}"
        DB_HOST_PORT="${DB_HOST_PORT_DB%%/*}"
        export DB_HOST="${DB_HOST_PORT%%:*}"
        export DB_PORT="${DB_HOST_PORT#*:}"
        export DB_NAME="${DB_HOST_PORT_DB#*/}"

        echo "✅ Parsed database connection from DATABASE_URL"
        echo "   DB_HOST: $DB_HOST"
        echo "   DB_PORT: $DB_PORT"
        echo "   DB_USER: $DB_USER"
        echo "   DB_NAME: $DB_NAME"
    fi
}

# Function to wait for PostgreSQL
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    MAX_TRIES=30
    COUNT=0

    until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c '\q' 2>/dev/null; do
        COUNT=$((COUNT + 1))
        if [ $COUNT -ge $MAX_TRIES ]; then
            echo "❌ ERROR: PostgreSQL did not become ready in time"
            exit 1
        fi
        echo "   Waiting... (attempt $COUNT/$MAX_TRIES)"
        sleep 2
    done
    echo "✅ PostgreSQL is ready!"
}

# Function to create odoo user if using postgres superuser
create_odoo_user() {
    if [ "$DB_USER" = "postgres" ]; then
        echo "Detected 'postgres' superuser - creating dedicated 'odoo' user..."

        # Check if odoo user already exists
        USER_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='odoo'" 2>/dev/null || echo "0")

        if [ "$USER_EXISTS" != "1" ]; then
            echo "Creating 'odoo' database user..."
            PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE USER odoo WITH PASSWORD '${DB_PASSWORD}' CREATEDB"
            echo "✅ User 'odoo' created!"
        else
            echo "✅ User 'odoo' already exists"
        fi

        # Update DB_USER to use odoo instead of postgres
        export DB_USER="odoo"
        echo "✅ Switched to using 'odoo' user for Odoo operations"
    fi
}

# Function to create database
create_database_if_not_exists() {
    echo "Checking if database '$DB_NAME' exists..."
    DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || echo "0")

    if [ "$DB_EXISTS" != "1" ]; then
        echo "Creating database '$DB_NAME'..."
        PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE \"$DB_NAME\""
        echo "✅ Database created!"
    else
        echo "✅ Database already exists"
    fi
}

# Function to substitute environment variables using envsubst
substitute_env_vars() {
    echo "Substituting environment variables in odoo.conf..."

    # Export all variables for envsubst
    export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME ADMIN_PASSWORD

    # Use envsubst to replace variables from template
    envsubst < /tmp/odoo.conf.template > /tmp/odoo.conf

    echo "✅ Configuration file prepared!"
    echo ""
    echo "Database configuration:"
    grep -E "^db_(host|port|user|name)" /tmp/odoo.conf || echo "   (no db config found)"
    echo ""
}

# Main execution
echo "=========================================="
echo "🚀 Starting Odoo Railway Deployment"
echo "=========================================="
echo ""

# Parse DATABASE_URL
parse_database_url

# Check required variables
REQUIRED_VARS=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME" "ADMIN_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ ERROR: Required environment variables missing:"
    printf '   - %s\n' "${MISSING_VARS[@]}"
    echo ""
    echo "Railway setup required:"
    echo "1. Add PostgreSQL database (provides DATABASE_URL)"
    echo "2. Set ADMIN_PASSWORD in service variables"
    exit 1
fi

echo "✅ All required variables are set"
echo ""

# Wait for PostgreSQL
wait_for_postgres
echo ""

# Create odoo user if needed (Railway uses postgres superuser by default)
create_odoo_user
echo ""

# Create database
create_database_if_not_exists
echo ""

# Prepare config
substitute_env_vars

# Initialize module if requested
if [ "$INIT_DB" = "true" ]; then
    echo "Initializing database with invoice_payment_details module..."
    /usr/bin/odoo -c /tmp/odoo.conf -i invoice_payment_details --stop-after-init
    echo ""
fi

# Update module if requested
if [ "$UPDATE_MODULE" = "true" ]; then
    echo "Updating invoice_payment_details module..."
    /usr/bin/odoo -c /tmp/odoo.conf -u invoice_payment_details --stop-after-init
    echo ""
fi

# Start Odoo
echo "=========================================="
echo "🎯 Starting Odoo server..."
echo "=========================================="
exec /usr/bin/odoo -c /tmp/odoo.conf