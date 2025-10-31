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

# Check AWS configuration
if command -v aws >/dev/null 2>&1; then
  echo ""
  echo "Checking AWS configuration..."
  
  # Check if credentials are configured
  if aws configure list | grep -q "access_key"; then
    echo "✓ AWS credentials are configured"
    
    # Check if credentials are valid by attempting to get caller identity
    if aws sts get-caller-identity >/dev/null 2>&1; then
      echo "✓ AWS credentials are valid and working"
      
      # Get and display account information
      ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
      USER_ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
      echo "  Account ID: $ACCOUNT_ID"
      echo "  User/Role: $USER_ARN"
    else
      echo "✗ AWS credentials are configured but not valid or cannot access AWS"
      echo "  Please check your credentials and network connection"
      exit 1
    fi
    
    # Check if default region is set
    DEFAULT_REGION=$(aws configure get region 2>/dev/null)
    if [ -n "$DEFAULT_REGION" ]; then
      echo "✓ Default region is set: $DEFAULT_REGION"
    else
      echo "⚠ Warning: No default region configured"
      echo "  Set a region with: aws configure set region <region-name>"
    fi
  else
    echo "✗ AWS credentials are not configured"
    echo "  Run 'aws configure sso' to set up your credentials using SSO or run 'aws configure' to set up your credentials using IAM credentials."
    echo "  In order to use SSO, you must have a valid SSO session. You can create a SSO session by running 'aws sso login' or 'aws sso login --profile <profile-name>'."
    echo "  For more information, see the AWS CLI documentation: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html"
    exit 1
  fi
fi

