FROM odoo:16.0

# Switch to root to install system dependencies
USER root

# Install additional system dependencies if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create custom addons directory
RUN mkdir -p /mnt/extra-addons/invoice_payment_details

# Copy the entire module to the custom addons directory
COPY . /mnt/extra-addons/invoice_payment_details/

# Copy the Railway entrypoint script
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Copy custom Odoo configuration
COPY odoo.conf /etc/odoo/odoo.conf

# Set proper ownership
RUN chown -R odoo:odoo /mnt/extra-addons/invoice_payment_details
RUN chown odoo:odoo /etc/odoo/odoo.conf

# Switch back to odoo user
USER odoo

# Expose Odoo port
EXPOSE 8069

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["odoo"]
