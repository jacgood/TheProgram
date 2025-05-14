FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Apache and necessary modules
RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-ldap-userdir \
    curl gnupg2 software-properties-common && \
    a2enmod ssl dav dav_fs ldap authnz_ldap proxy proxy_http proxy_wstunnel rewrite cgi cgid actions

# Add WebDNA repository
RUN curl https://deb.webdna.us/ubuntu23/webdna.key | gpg --dearmor > webdna.gpg && \
    install -o root -g root -m 644 webdna.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/webdna.gpg] https://deb.webdna.us/ubuntu23 lunar non-free" | tee -a /etc/apt/sources.list && \
    apt-get update

# Install WebDNA with systemd bypass
RUN mkdir -p /usr/local/bin && \
    echo '#!/bin/sh' > /usr/local/bin/systemctl && \
    echo 'exit 0' >> /usr/local/bin/systemctl && \
    chmod +x /usr/local/bin/systemctl && \
    apt-get install -y libapache2-mod-webdna=8.6.5 || true && \
    rm /usr/local/bin/systemctl

# Copy Apache configurations
COPY apache2.conf /etc/apache2/apache2.conf
COPY sites-available/goodval.conf /etc/apache2/sites-available/goodval.conf
COPY sites-available/goodval.wfd.conf /etc/apache2/sites-available/goodval.wfd.conf
COPY conf-available/webdna.conf /etc/apache2/conf-available/webdna.conf
COPY conf-available/webdna-fix.conf /etc/apache2/conf-available/webdna-fix.conf
COPY sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable configurations
RUN a2enconf webdna.conf && \
    a2enconf webdna-fix.conf && \
    a2enmod webdna cgi cgid && \
    a2ensite 000-default.conf goodval.conf goodval.wfd.conf

# Copy SSL Certificates
COPY certs/ /etc/ssl/certs/

# Copy and enable startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Ensure proper permissions for web directories
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose ports
EXPOSE 80 443

# Start Apache and WebDNA
CMD ["/startup.sh"]