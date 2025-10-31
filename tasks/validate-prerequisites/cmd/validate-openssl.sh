#!/usr/bin/env bash

# Validate OpenSSL installation
if command -v openssl >/dev/null 2>&1; then
  echo "OpenSSL is installed."
else
  echo "OpenSSL is not installed."
  echo "To install OpenSSL, run:"
  echo "brew install openssl"
fi
