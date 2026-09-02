#!/bin/bash
# WARNING: This script creates real GitHub repository secrets that enable
# AWS deployments and can trigger real AWS billing. Run it only with
# explicit approval and a confirmed billing/usage plan.
# GitHub Actions Secrets Setup Helper
# Run this after setting up AWS IAM roles and Cognito

set -e

echo "=========================================="
echo "Poultry Farm — GitHub Actions Secrets Setup"
echo "=========================================="
echo ""
echo "This script helps you set up repository secrets for CI/CD."
echo "PREREQUISITE: You must have set up AWS IAM roles manually."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI (gh) is not installed."
    echo "Install from: https://cli.github.com"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q)
echo -e "${GREEN}Repository: $REPO${NC}"
echo ""

# Prompt for manual inputs
echo -e "${YELLOW}MANUAL STEPS REQUIRED:${NC}"
echo "Before proceeding, ensure you have:"
echo "1. Created AWS IAM roles for GitHub Actions"
echo "2. Set up Cognito user pool (if not already done)"
echo "3. Have the following values ready:"
echo ""

read -p "Enter AWS Account ID (12 digits): " AWS_ACCOUNT_ID
read -p "Enter AWS Role ARN for DEV (arn:aws:iam::...): " AWS_ROLE_ARN_DEV
read -p "Enter AWS Role ARN for PROD (arn:aws:iam::...): " AWS_ROLE_ARN_PROD

# Validate inputs
if [[ ! $AWS_ACCOUNT_ID =~ ^[0-9]{12}$ ]]; then
    echo "ERROR: Invalid AWS Account ID"
    exit 1
fi

# Set secrets
echo ""
echo -e "${YELLOW}Setting repository secrets...${NC}"

gh secret set AWS_ACCOUNT_ID -b "$AWS_ACCOUNT_ID"
echo "✓ AWS_ACCOUNT_ID"

gh secret set AWS_ROLE_ARN_DEV -b "$AWS_ROLE_ARN_DEV"
echo "✓ AWS_ROLE_ARN_DEV"

gh secret set AWS_ROLE_ARN_PROD -b "$AWS_ROLE_ARN_PROD"
echo "✓ AWS_ROLE_ARN_PROD"

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Next steps:"
echo "1. Manual: Set environment variables in AWS Secrets Manager:"
echo "   - poultry/dev/jwt-secret"
echo "   - poultry/dev/db-password"
echo "   - poultry/prod/jwt-secret"
echo "   - poultry/prod/db-password"
echo ""
echo "2. Verify secrets with: gh secret list"
echo "3. Push code to dev/main branch to trigger deployment"
