#!/usr/bin/env bash

# Validate AWS CLI installation
if command -v aws >/dev/null 2>&1; then
  echo "AWS CLI is installed."
else
  echo "AWS CLI is not installed."
  echo "To install AWS CLI, run:"
  echo "brew install awscli"
fi

if command -v aws >/dev/null 2>&1; then
  AWS_VERSION=$(aws --version 2>&1)
  echo "AWS CLI version: $AWS_VERSION"
fi

