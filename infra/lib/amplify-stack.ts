import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
import * as route53 from 'aws-cdk-lib/aws-route53';

export interface AmplifyStackProps extends cdk.StackProps {
  githubToken: string;
  githubOwner: string;
  githubRepo: string;
  hostedZoneName?: string; // e.g., 'trakkyfood.it'
}

export class AmplifyStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AmplifyStackProps) {
    super(scope, id, props);

    // Import existing Route 53 hosted zone
    const hostedZoneName = props.hostedZoneName || 'trakkyfood.it';
    const hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
      domainName: hostedZoneName,
    });

    // Create the Amplify app
    const amplifyApp = new amplify.App(this, 'TrakkyFoodLandingPageApp', {
      appName: 'trakkyfood-landing-page',
      sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
        owner: props.githubOwner,
        repository: props.githubRepo,
        oauthToken: cdk.SecretValue.unsafePlainText(props.githubToken),
      }),
      autoBranchDeletion: true,
      environmentVariables: {
        // These will be overridden per branch
      },
    });

    // Shared build specification for all branches
    const buildSpec = codebuild.BuildSpec.fromObjectToYaml({
      version: '1.0',
      frontend: {
        phases: {
          preBuild: {
            commands: [
              'npm ci',
            ],
          },
          build: {
            commands: [
              'npm run build',
            ],
          },
        },
        artifacts: {
          baseDirectory: 'dist',
          files: [
            '**/*',
          ],
        },
        cache: {
          paths: [
            'node_modules/**/*',
          ],
        },
      },
    });

    // Configure main branch (dev environment)
    const mainBranch = amplifyApp.addBranch('main', {
      autoBuild: true,
      environmentVariables: {
        // No environment variables needed for Astro build
      },
      buildSpec: buildSpec,
    });

    // Configure prod branch (prod environment)
    const prodBranch = amplifyApp.addBranch('prod', {
      autoBuild: true,
      environmentVariables: {
        // No environment variables needed for Astro build
      },
      buildSpec: buildSpec,
    });

    // Add custom domain for dev environment (dev-landing-page.trakkyfood.it)
    const devDomain = amplifyApp.addDomain('DevDomain', {
      domainName: 'dev-landing-page.trakkyfood.it',
    });
    devDomain.mapRoot(mainBranch); // Map root domain to main branch

    // Add custom domain for prod environment (trakkyfood.it)
    const prodDomain = amplifyApp.addDomain('ProdDomain', {
      domainName: 'trakkyfood.it',
    });
    prodDomain.mapRoot(prodBranch); // Map root domain to prod branch

    // Add custom headers for dev domain to prevent search engine indexing
    // Note: Custom headers are added via Amplify's custom rules
    amplifyApp.addCustomRule({
      source: '/<*>',
      target: '/index.html',
      status: amplify.RedirectStatus.NOT_FOUND_REWRITE,
    });

    // For preventing search engine indexing on dev, we'll use custom headers
    // This is configured via the Amplify console or can be done via CDK custom headers
    // The X-Robots-Tag header will be set via Amplify's custom headers feature
    // Note: The CDK Amplify construct doesn't directly support custom headers per domain,
    // so this may need to be configured manually in the Amplify console after deployment
    // or we can use a workaround with CloudFront distribution (more complex)

    // Output the app URL
    new cdk.CfnOutput(this, 'AmplifyAppId', {
      value: amplifyApp.appId,
      description: 'Amplify App ID',
    });

    new cdk.CfnOutput(this, 'DevDomainUrl', {
      value: 'https://dev-landing-page.trakkyfood.it',
      description: 'Dev environment URL (main branch)',
    });

    new cdk.CfnOutput(this, 'ProdDomainUrl', {
      value: 'https://trakkyfood.it',
      description: 'Prod environment URL (prod branch)',
    });

    new cdk.CfnOutput(this, 'MainBranchUrl', {
      value: `https://main.${amplifyApp.defaultDomain}`,
      description: 'Main branch default Amplify URL',
    });

    new cdk.CfnOutput(this, 'ProdBranchUrl', {
      value: `https://prod.${amplifyApp.defaultDomain}`,
      description: 'Prod branch default Amplify URL',
    });
  }
}

