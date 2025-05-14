#!/bin/bash
# Script to obtain and renew Let's Encrypt wildcard certificates using Cloudflare DNS

# Domain for which to obtain the certificate
DOMAIN="${CERTIFICATE_DOMAIN:-goodvaluation.com}"

# Email for Let's Encrypt notifications
EMAIL="${LETSENCRYPT_EMAIL:-your-email@example.com}"

# Certbot command with Cloudflare DNS plugin
certbot certonly --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email \
  -d "$DOMAIN" \
  -d "*.$DOMAIN" \
  --preferred-challenges dns-01 \
  --server https://acme-v02.api.letsencrypt.org/directory

# Copy certificates to the correct location for Apache
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  # Create a combined certificate for Apache
  cat /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/ssl/certs/goodvaluation.com.key
  cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem > /etc/ssl/certs/goodvaluation.com.crt
  
  # Set proper permissions
  chmod 600 /etc/ssl/certs/goodvaluation.com.key
  chmod 644 /etc/ssl/certs/goodvaluation.com.crt
  
  # Create symbolic links for specific subdomains if needed
  ln -sf /etc/ssl/certs/goodvaluation.com.key /etc/ssl/certs/wfd.goodvaluation.com.key
  ln -sf /etc/ssl/certs/goodvaluation.com.crt /etc/ssl/certs/wfd.goodvaluation.com.crt
  ln -sf /etc/ssl/certs/goodvaluation.com.key /etc/ssl/certs/server.key
  ln -sf /etc/ssl/certs/goodvaluation.com.crt /etc/ssl/certs/server.crt
  
  echo "Certificates have been successfully renewed and installed."
else
  echo "Certificate renewal failed. Check the logs for more information."
  exit 1
fi

# Signal Apache to reload the certificates
if [ -S /var/run/apache2/apache2.sock ]; then
  echo "Reloading Apache configuration..."
  apachectl -k graceful
fi
