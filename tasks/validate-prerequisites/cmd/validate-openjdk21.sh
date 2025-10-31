#!/usr/bin/env bash

# Validate OpenJDK 21 installation
if command -v java >/dev/null 2>&1; then
  JAVA_VERSION=$(java -version 2>&1 | grep 'openjdk version "21')
  if [ -n "$JAVA_VERSION" ]; then
    echo "OpenJDK 21 is installed."
  else
    echo "Java is installed, but not OpenJDK 21."
    echo "To install OpenJDK 21, run:"
    echo "brew install openjdk@21"
  fi
else
  echo "Java is not installed."
  echo "To install OpenJDK 21, run:"
  echo "brew install openjdk@21"
fi
