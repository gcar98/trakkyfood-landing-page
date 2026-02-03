@echo off
setlocal enabledelayedexpansion

echo Starting CDK deployment...

REM Check if .env file exists
if not exist .env (
    echo Error: .env file not found in project root
    exit /b 1
)

REM Load .env file
echo Loading environment variables from .env...
for /f "usebackq eol=# tokens=1,* delims==" %%a in (".env") do (
    set "key=%%a"
    set "value=%%b"
    REM Remove leading/trailing spaces from key
    for /f "tokens=*" %%k in ("!key!") do set "key=%%k"
    REM Remove leading/trailing spaces from value
    for /f "tokens=*" %%v in ("!value!") do set "value=%%v"
    REM Remove quotes from value if present
    if "!value:~0,1!"=="^"" set "value=!value:~1,-1!"
    if "!value:~0,1!"=="'" set "value=!value:~1,-1!"
    if not "!key!"=="" (
        set "!key!=!value!"
    )
)

REM Validate required variables
set MISSING_VARS=
if not defined AWS_ACCOUNT set MISSING_VARS=!MISSING_VARS! AWS_ACCOUNT
if not defined AWS_REGION set MISSING_VARS=!MISSING_VARS! AWS_REGION
if not defined GITHUB_TOKEN set MISSING_VARS=!MISSING_VARS! GITHUB_TOKEN
if not defined GITHUB_OWNER set MISSING_VARS=!MISSING_VARS! GITHUB_OWNER
if not defined GITHUB_REPO set MISSING_VARS=!MISSING_VARS! GITHUB_REPO

REM AWS credentials are optional if using AWS CLI default profile
if not defined AWS_ACCESS_KEY_ID (
    echo Warning: AWS_ACCESS_KEY_ID not set, using AWS CLI default profile
)
if not defined AWS_SECRET_ACCESS_KEY (
    echo Warning: AWS_SECRET_ACCESS_KEY not set, using AWS CLI default profile
)

if not "!MISSING_VARS!"=="" (
    echo Error: Missing required environment variables:!MISSING_VARS!
    exit /b 1
)

REM Export AWS credentials if provided
if defined AWS_ACCESS_KEY_ID set AWS_ACCESS_KEY_ID=!AWS_ACCESS_KEY_ID!
if defined AWS_SECRET_ACCESS_KEY set AWS_SECRET_ACCESS_KEY=!AWS_SECRET_ACCESS_KEY!

REM Export AWS region
set AWS_DEFAULT_REGION=!AWS_REGION!

REM Export CDK context
set CDK_DEFAULT_ACCOUNT=!AWS_ACCOUNT!
set CDK_DEFAULT_REGION=!AWS_REGION!

REM Export GitHub variables for CDK
set GITHUB_TOKEN=!GITHUB_TOKEN!
set GITHUB_OWNER=!GITHUB_OWNER!
set GITHUB_REPO=!GITHUB_REPO!

echo Environment variables loaded successfully
echo AWS Account: !AWS_ACCOUNT!
echo AWS Region: !AWS_REGION!
echo GitHub Owner: !GITHUB_OWNER!
echo GitHub Repo: !GITHUB_REPO!

REM Change to infra directory
if not exist "infra" (
    echo Error: infra directory not found
    exit /b 1
)
cd infra

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo Installing CDK dependencies...
    call npm install
    if errorlevel 1 (
        echo Error: npm install failed
        exit /b 1
    )
) else (
    echo CDK dependencies already installed
)

REM Check if CDK is bootstrapped
echo Checking if CDK is bootstrapped...
set BOOTSTRAP_STACK_NAME=CDKToolkit

aws cloudformation describe-stacks --stack-name %BOOTSTRAP_STACK_NAME% --region %AWS_REGION% >nul 2>&1
if errorlevel 1 (
    echo CDK not bootstrapped. Bootstrapping now...
    call npx cdk bootstrap aws://%AWS_ACCOUNT%/%AWS_REGION%
    if errorlevel 1 (
        echo Error: CDK bootstrap failed
        exit /b 1
    )
    echo CDK bootstrap completed
) else (
    echo CDK is already bootstrapped
)

REM Deploy the stack
echo Deploying CDK stack...
call npx cdk deploy --all --require-approval never

if errorlevel 1 (
    echo Deployment failed
    exit /b 1
) else (
    echo Deployment completed successfully!
)

endlocal

