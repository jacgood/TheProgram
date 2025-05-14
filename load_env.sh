#!/bin/bash
# Script to load environment variables from .env file

# Check if .env file exists
if [ -f .env ]; then
  echo "Loading environment variables from .env file..."
  export $(grep -v '^#' .env | xargs)
else
  echo "No .env file found. Please create one based on env.example."
  echo "cp env.example .env"
  echo "Then edit .env with your actual values."
  exit 1
fi

# Verify that required variables are set
required_vars=(
  "LDAP_URL"
  "LDAP_BIND_DN"
  "LDAP_BIND_PASSWORD"
  "LDAP_GROUP"
  "SSL_CERT_FILE"
  "SSL_KEY_FILE"
  "MAIN_SSL_CERT_FILE"
  "MAIN_SSL_KEY_FILE"
)

missing_vars=0
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required environment variable $var is not set in .env file."
    missing_vars=$((missing_vars + 1))
  fi
done

if [ $missing_vars -gt 0 ]; then
  echo "Please set all required variables in your .env file."
  exit 1
fi

echo "Environment variables loaded successfully."
