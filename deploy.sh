#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting CDK deployment...${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found in project root${NC}"
    exit 1
fi

# Load .env file
echo -e "${YELLOW}Loading environment variables from .env...${NC}"
set -a  # Automatically export all variables
source .env
set +a  # Stop automatically exporting

# Validate required variables
REQUIRED_VARS=("AWS_ACCOUNT" "AWS_REGION" "GITHUB_TOKEN" "GITHUB_OWNER" "GITHUB_REPO")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

# AWS credentials are optional if using AWS CLI default profile
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}Warning: AWS_ACCESS_KEY_ID not set, using AWS CLI default profile${NC}"
fi
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${YELLOW}Warning: AWS_SECRET_ACCESS_KEY not set, using AWS CLI default profile${NC}"
fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "${RED}  - $var${NC}"
    done
    exit 1
fi

# Export AWS credentials if provided
if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    export AWS_ACCESS_KEY_ID
fi
if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    export AWS_SECRET_ACCESS_KEY
fi
export AWS_DEFAULT_REGION="$AWS_REGION"

# Export GitHub token for CDK
export GITHUB_TOKEN
export GITHUB_OWNER
export GITHUB_REPO

# Export CDK context
export CDK_DEFAULT_ACCOUNT="$AWS_ACCOUNT"
export CDK_DEFAULT_REGION="$AWS_REGION"

echo -e "${GREEN}Environment variables loaded successfully${NC}"
echo -e "${YELLOW}AWS Account: $AWS_ACCOUNT${NC}"
echo -e "${YELLOW}AWS Region: $AWS_REGION${NC}"
echo -e "${YELLOW}GitHub Owner: $GITHUB_OWNER${NC}"
echo -e "${YELLOW}GitHub Repo: $GITHUB_REPO${NC}"

# Change to infra directory
cd infra || exit 1

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing CDK dependencies...${NC}"
    npm install
else
    echo -e "${GREEN}CDK dependencies already installed${NC}"
fi

# Check if CDK is bootstrapped
echo -e "${YELLOW}Checking if CDK is bootstrapped...${NC}"
BOOTSTRAP_STACK_NAME="CDKToolkit"

if aws cloudformation describe-stacks --stack-name "$BOOTSTRAP_STACK_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo -e "${GREEN}CDK is already bootstrapped${NC}"
else
    echo -e "${YELLOW}CDK not bootstrapped. Bootstrapping now...${NC}"
    npx cdk bootstrap aws://"$AWS_ACCOUNT"/"$AWS_REGION"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: CDK bootstrap failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}CDK bootstrap completed${NC}"
fi

# Deploy the stack
echo -e "${YELLOW}Deploying CDK stack...${NC}"
npx cdk deploy --all --require-approval never

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Deployment completed successfully!${NC}"
else
    echo -e "${RED}Deployment failed${NC}"
    exit 1
fi

