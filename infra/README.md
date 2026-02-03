# TrakkyFood Landing Page - AWS Amplify Infrastructure

This directory contains the AWS CDK infrastructure code for deploying the TrakkyFood Landing Page Astro application to AWS Amplify.

## Overview

The CDK stack provisions an AWS Amplify app that:
- Connects to your GitHub repository
- Automatically builds and deploys on commits to `main` branch (dev environment)
- Automatically builds and deploys on commits to `prod` branch (prod environment)
- Maps custom domains: `dev-landing-page.trakkyfood.it` (main) and `trakkyfood.it` (prod)

## Prerequisites

1. **AWS Account**: You need an AWS account with appropriate permissions
2. **AWS CLI**: Install and configure AWS CLI
3. **Node.js**: Version 18.x or later
4. **CDK CLI**: Install globally with `npm install -g aws-cdk`
5. **GitHub Token**: A personal access token with `repo` scope
6. **Route53 Hosted Zone**: The domain `trakkyfood.it` must have a hosted zone in Route53

## Setup

### 1. Configure Environment Variables

Create a `.env` file in the project root (see `.env.example` for reference) with the following variables:

```env
AWS_ACCOUNT=your-aws-account-id
AWS_REGION=eu-central-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
GITHUB_TOKEN=your-github-token
GITHUB_OWNER=your-github-username-or-org
GITHUB_REPO=trakkyfood-landing-page
```

**Note**: Replace all placeholder values with your actual credentials and repository information.

### 2. Install Dependencies

```bash
cd infra
npm install
```

### 3. Bootstrap CDK (First Time Only)

If this is your first time using CDK in this AWS account/region, you need to bootstrap:

```bash
cd infra
cdk bootstrap aws://YOUR_ACCOUNT_ID/eu-central-1
```

Or use the deployment script which will handle this automatically.

## Deployment

### Using the Deployment Script (Recommended)

From the project root, run:

```bash
./deploy.sh
```

Or on Windows:

```bash
bash deploy.sh
```

The script will:
1. Load environment variables from `.env`
2. Validate required variables
3. Export AWS credentials
4. Bootstrap CDK if needed (first time only)
5. Install CDK dependencies
6. Deploy the stack

### Manual Deployment

If you prefer to deploy manually:

```bash
cd infra

# Export environment variables
export AWS_ACCOUNT=your-account-id
export AWS_REGION=eu-central-1
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export GITHUB_TOKEN=your-token
export GITHUB_OWNER=your-username
export GITHUB_REPO=trakkyfood-landing-page

# Deploy
cdk deploy
```

## Stack Outputs

After deployment, the stack will output:
- **AmplifyAppId**: The Amplify App ID
- **DevDomainUrl**: The URL for the dev environment (main branch): `https://dev-landing-page.trakkyfood.it`
- **ProdDomainUrl**: The URL for the prod environment (prod branch): `https://trakkyfood.it`
- **MainBranchUrl**: The default Amplify URL for the main branch
- **ProdBranchUrl**: The default Amplify URL for the prod branch

## Build Configuration

The Amplify app is configured with:
- **Build command**: `npm ci && npm run build`
- **Output directory**: `dist`
- **Framework**: Astro (static site generator)

## Branch Behavior

- **main branch**: 
  - Auto-builds on every commit
  - Deploys to dev environment
  - Custom domain: `dev-landing-page.trakkyfood.it`
  
- **prod branch**:
  - Auto-builds on every commit
  - Deploys to prod environment
  - Custom domain: `trakkyfood.it`

## Search Engine Indexing Prevention (Dev Environment)

To prevent search engines from indexing the dev environment (`dev-landing-page.trakkyfood.it`), you have two options:

### Option 1: Custom Headers (Recommended)

After deployment, configure custom headers in the AWS Amplify Console:

1. Go to AWS Amplify Console
2. Select your app
3. Go to **Rewrites and redirects** section
4. Add a custom header rule:
   - **Source address**: `https://dev-landing-page.trakkyfood.it/<*>`
   - **Target**: `https://dev-landing-page.trakkyfood.it/<*>`
   - **Type**: Custom header
   - **Header name**: `X-Robots-Tag`
   - **Header value**: `noindex, nofollow`

This is the most reliable method as HTTP headers are respected by all major search engines.

### Option 2: robots.txt Rewrite

Alternatively, you can use Amplify's rewrite rules to serve a blocking robots.txt for the dev domain:

1. Go to AWS Amplify Console
2. Select your app → **Rewrites and redirects**
3. Add a rewrite rule:
   - **Source address**: `https://dev-landing-page.trakkyfood.it/robots.txt`
   - **Target**: Create a custom response or rewrite to serve:
     ```
     User-agent: *
     Disallow: /
     ```

**Note**: The CDK Amplify alpha construct doesn't directly support per-domain custom headers, so this configuration needs to be done manually in the Amplify Console after deployment.

## Troubleshooting

### CDK Bootstrap Issues

If you encounter bootstrap errors, ensure:
- Your AWS credentials have sufficient permissions
- The target region is correct
- You're using the correct AWS account ID

### GitHub Connection Issues

If Amplify cannot connect to GitHub:
- Verify your GitHub token has `repo` scope
- Check that `GITHUB_OWNER` and `GITHUB_REPO` are correct
- Ensure the repository exists and is accessible with the provided token

### Build Failures

If builds fail in Amplify:
- Check the build logs in the Amplify console
- Verify your `package.json` has the correct build script (`npm run build`)
- Ensure all dependencies are listed in `package.json`
- Check that the output directory is `dist` (Astro's default)

### Domain Issues

If custom domains are not working:
- Verify the Route53 hosted zone exists for `trakkyfood.it`
- Check that DNS records are properly configured
- Wait for DNS propagation (can take up to 48 hours)
- Verify SSL certificates are issued (Amplify handles this automatically)

## Cleanup

To destroy the stack:

```bash
cd infra
cdk destroy
```

**Warning**: This will delete the Amplify app and all associated resources, including custom domains.

## Additional Resources

- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [Amplify CDK Construct](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-amplify-alpha-readme.html)
- [Astro Documentation](https://docs.astro.build/)

