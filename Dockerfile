FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Apache and necessary modules
RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-ldap-userdir \
    curl gnupg2 software-properties-common && \
    a2enmod ssl dav dav_fs ldap authnz_ldap proxy proxy_http proxy_wstunnel rewrite cgid

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
    rm /usr/local/bin/systemctl && \
    # Manually enable WebDNA module in case it failed during package installation
    a2enmod webdna || true && \
    # Create WebDNA directories if needed
    mkdir -p /var/www/html/WebCatalog

# Copy Apache configurations
COPY apache2.conf /etc/apache2/apache2.conf
COPY conf-available/goodval.conf /etc/apache2/conf-available/goodval.conf
#COPY conf-available/goodval.wfd.conf /etc/apache2/conf-available/goodval.wfd.conf
COPY sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

# Add WebDNA Apache configuration if not already handled by package
RUN echo "AddHandler webdna-handler .dna" >> /etc/apache2/apache2.conf && \
    echo "Action webdna-handler /cgi-bin/webdna" >> /etc/apache2/apache2.conf

#Enable confs
RUN a2enconf goodval.conf 
#RUN a2enconf goodval.wfd.conf 

# Enable sites
RUN a2ensite default-ssl.conf 000-default.conf

# Copy SSL Certificates
COPY certs/ /etc/ssl/certs/

# Ensure proper permissions for web directories
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Expose ports
EXPOSE 80 443

# Start Apache
CMD ["apachectl", "-D", "FOREGROUND"]