#!/usr/bin/env bash

echo "Installing Python packages from requirements.txt..."
.venv/bin/python3 -m pip install --upgrade pip
.venv/bin/python3 -m pip install -r requirements.txt
echo "✅ Packages installed successfully"
