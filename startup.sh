#!/bin/bash

echo "Starting WebDNA service..."
if [ -f /etc/init.d/webdna ]; then
    # Start the WebDNA service explicitly
    /etc/init.d/webdna start
    
    # Check if it's running
    echo "WebDNA service status:"
    /etc/init.d/webdna status || true
fi

echo "Setting up WebDNA CGI..."
# Create CGI directory if needed
mkdir -p /usr/lib/cgi-bin/

# Find and link the WebDNA executable
if [ -f /usr/lib/cgi-bin/webdna ]; then
    echo "WebDNA CGI already exists"
    chmod 755 /usr/lib/cgi-bin/webdna
else
    # Find the WebDNA executable
    WEBDNA_PATH=$(find /usr -name "webdna" -type f -not -path "*/\.*" 2>/dev/null | head -1)
    
    if [ -n "$WEBDNA_PATH" ]; then
        echo "Found WebDNA at $WEBDNA_PATH"
        cp "$WEBDNA_PATH" /usr/lib/cgi-bin/webdna
        chmod 755 /usr/lib/cgi-bin/webdna
    else
        echo "Creating CGI wrapper for WebDNA module"
        # Create a simple CGI wrapper script
        cat > /usr/lib/cgi-bin/webdna << 'EOL'
#!/bin/sh
# WebDNA CGI wrapper
exec /usr/lib/apache2/modules/mod_webdna.so "$@"
EOL
        chmod 755 /usr/lib/cgi-bin/webdna
    fi
fi

# Create test files in different locations
echo "Creating WebDNA test files..."
mkdir -p /var/www/html/test
echo "[WebDNA-Info][ServerInfo][/ServerInfo][/WebDNA-Info]" > /var/www/html/test/simple.dna
echo "<html><body><h1>WebDNA Test</h1>[WebDNA-Info][ServerInfo][/ServerInfo][/WebDNA-Info]</body></html>" > /var/www/html/test.dna

# Set permissions
chmod 755 /var/www/html/test/simple.dna /var/www/html/test.dna

# Check if the WebDNA interpreter is working
echo "Testing WebDNA interpreter..."
if [ -f /usr/lib/cgi-bin/webdna ]; then
    /usr/lib/cgi-bin/webdna -v || echo "WebDNA version check failed"
    
    # Test with a sample file
    echo "[WebDNA-Info][ServerInfo][/ServerInfo][/WebDNA-Info]" > /tmp/test.dna
    /usr/lib/cgi-bin/webdna /tmp/test.dna || echo "WebDNA processing test failed"
fi

# Enable the CGI module
a2enmod cgi

# Restart WebDNA service to ensure it's running with the latest configuration
if [ -f /etc/init.d/webdna ]; then
    /etc/init.d/webdna restart
fi

echo "Checking Apache configuration..."
apachectl configtest

# Run Apache in foreground
echo "Starting Apache..."
exec apachectl -D FOREGROUND