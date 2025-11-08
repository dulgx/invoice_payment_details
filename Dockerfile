FROM odoo:16.0

USER root

# Install gettext for envsubst and postgresql-client
RUN apt-get update && \
    apt-get install -y gettext postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy custom addons
COPY ./addons /mnt/extra-addons

# Copy Odoo configuration file
COPY ./odoo.conf /etc/odoo/odoo.conf

# Copy custom entrypoint script
COPY ./entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

# Copy and install additional Python dependencies
COPY ./requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt || true

# Set proper permissions
RUN chown -R odoo:odoo /mnt/extra-addons

USER odoo

EXPOSE 8069

ENTRYPOINT ["/railway-entrypoint.sh"]