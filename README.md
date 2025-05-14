# TheProgram

A containerized web application using Apache, WebDNA, and LDAP authentication.

## Security Notice

This repository has been configured to exclude sensitive data from being pushed to GitHub. The following measures have been implemented:

1. Updated `.gitignore` to exclude sensitive files and directories
2. Replaced hardcoded credentials with environment variables
3. Added template files for environment configuration

## Setup Instructions

### Environment Configuration

1. Copy the environment template to create your `.env` file:
   ```bash
   cp env.example .env
   ```

2. Edit the `.env` file with your actual credentials and configuration values:
   ```
   # LDAP Configuration
   LDAP_URL=ldap://your-ldap-server:389/your-search-base
   LDAP_BIND_DN=cn=your-bind-user,cn=Users,ou=YourOU,dc=YourDomain,dc=COM
   LDAP_BIND_PASSWORD=your-secure-password
   LDAP_GROUP=cn=YourGroup,ou=Groups,dc=YourDomain,dc=COM

   # SSL Configuration
   SSL_CERT_FILE=your-cert-file.crt
   SSL_KEY_FILE=your-key-file.key
   MAIN_SSL_CERT_FILE=your-main-cert-file.crt
   MAIN_SSL_KEY_FILE=your-main-key-file.key
   ```

3. Make sure your SSL certificates are placed in the `certs/` directory

### Running the Application

Start the application using Docker Compose:

```bash
docker-compose up -d
```

The application will be available at:
- HTTP: http://localhost:8080 (redirects to HTTPS)
- HTTPS: https://localhost:8443

## Directory Structure

- `certs/`: SSL certificates (excluded from Git)
- `html/`: Web content (excluded from Git)
- `logs/`: Apache logs (excluded from Git)
- `sites-available/`: Apache virtual host configurations
- `conf-available/`: Apache module configurations

## SSL Certificates with Let's Encrypt and Cloudflare DNS

This project is configured to automatically obtain and renew wildcard SSL certificates using Let's Encrypt with Cloudflare DNS validation. This allows you to secure all subdomains with a single certificate.

### Setup Instructions

1. **Configure Cloudflare API Credentials**
   - Edit the `certbot/cloudflare.ini` file with your Cloudflare email and API key
   - Make sure this file has restricted permissions: `chmod 600 certbot/cloudflare.ini`

2. **Update Environment Variables**
   - In your `.env` file, set the following variables:
     ```
     CF_API_EMAIL=your-cloudflare-email@example.com
     CF_API_KEY=your-global-api-key
     CERTIFICATE_DOMAIN=goodvaluation.com
     LETSENCRYPT_EMAIL=your-email@example.com
     ```

3. **Start the Services**
   - Run `docker-compose up -d`
   - The Certbot container will automatically obtain certificates and renew them every 12 hours if needed

4. **Certificate Files**
   - Certificates are stored in the Docker volume `letsencrypt-certs`
   - Symbolic links are created in the `certs` directory for Apache to use

### Manual Certificate Renewal

If you need to manually renew the certificates, you can run:

```bash
docker-compose exec certbot /opt/renew-certs.sh
```

## Security Considerations

- Never commit the `.env` file or `certbot/cloudflare.ini` to version control
- Keep SSL certificates and keys secure
- Regularly update passwords and credentials
- Review Apache configurations for security best practices
