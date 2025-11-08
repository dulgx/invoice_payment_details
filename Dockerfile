FROM odoo:16.0

USER root

# Install gettext for envsubst and postgresql-client
RUN apt-get update && \
    apt-get install -y gettext postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Create custom addons directory
RUN mkdir -p /mnt/extra-addons/invoice_payment_details

# Copy the entire module to the custom addons directory
COPY . /mnt/extra-addons/invoice_payment_details/

# Copy Odoo config template (will be processed by entrypoint)
COPY odoo.conf /tmp/odoo.conf.template

# Copy and set up the entrypoint script
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Set proper permissions
RUN chown -R odoo:odoo /mnt/extra-addons/invoice_payment_details
RUN chown odoo:odoo /tmp/odoo.conf.template

USER odoo

EXPOSE 8069

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["odoo"]