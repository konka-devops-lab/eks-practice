#!/bin/bash

echo "🌍 Choose the environment to provision:"
echo "1. dev"
echo "2. prod"

read -p "Enter your choice (1 or 2): " CHOICE

case "$CHOICE" in
  1)
    ENV="dev"
    ;;
  2)
    ENV="prod"
    ;;
  *)
    echo "❌ Invalid choice. Exiting."
    exit 1
    ;;
esac

cd live || exit 1

# Terraform Init
echo "🔧 Initializing Terraform with backend config for $ENV..."
time terraform init -backend-config=../env/$ENV/backend.tfvars

# Format and Validate
echo "🧹 Formatting Terraform files..."
time terraform fmt

echo "✅ Validating configuration..."
time terraform validate

# Terraform Plan
echo "📋 Planning Terraform changes for $ENV..."
time terraform plan -var-file=../env/$ENV/main.tfvars -out=tfplan.out

# Prompt for Apply
echo "❓ Do you want to apply this plan? (yes/no)"
read CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  echo "🚀 Applying Terraform changes..."
  time terraform apply tfplan.out
else
  echo "❌ Apply cancelled."
  exit 0
fi
