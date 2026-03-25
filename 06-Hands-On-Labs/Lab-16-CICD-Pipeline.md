# Lab 16: CI/CD Pipeline

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure DevOps project
- Azure subscription
- Application code in repository

## Objective
Create CI/CD pipeline for automated build, test, and deployment.

---

## Create Build Pipeline (YAML)

**azure-pipelines.yml**
```yaml
trigger:
  branches:
    include:
    - main
  paths:
    exclude:
    - README.md

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '20.x'
      displayName: 'Install Node.js'
    
    - script: |
        npm install
        npm run build
      displayName: 'npm install and build'
    
    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
      displayName: 'Publish Artifact'

- stage: Test
  dependsOn: Build
  jobs:
  - job: TestJob
    steps:
    - script: |
        npm install
        npm test
      displayName: 'Run tests'
    
    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'JUnit'
        testResultsFiles: '**/test-results.xml'
      displayName: 'Publish test results'

- stage: Deploy
  dependsOn: Test
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployWeb
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Azure-Connection'
              appName: 'myapp-prod'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
```

---

## Create Release Pipeline

```bash
# Create release definition
az pipelines release definition create \
  --project MyApp \
  --name "MyApp-Release" \
  --repository myapp-repo \
  --branch main
```

---

## Configure Deployment Stages

**Multi-stage deployment:**
```yaml
stages:
- stage: DeployDev
  jobs:
  - deployment: DeployToDev
    environment: 'dev'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Azure-Connection'
              appName: 'myapp-dev'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'

- stage: DeployStaging
  dependsOn: DeployDev
  jobs:
  - deployment: DeployToStaging
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Azure-Connection'
              appName: 'myapp-staging'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'

- stage: DeployProd
  dependsOn: DeployStaging
  jobs:
  - deployment: DeployToProduction
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Azure-Connection'
              appName: 'myapp-prod'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              deploymentMethod: 'zipDeploy'
```

---

## Configure Approvals

```bash
# Add approval to environment
az pipelines environment create \
  --name production \
  --project MyApp

# Configure manual approval (via Portal)
# Go to Pipelines → Environments → production → Approvals and checks
```

---

## Configure Variables

```bash
# Create variable group
az pipelines variable-group create \
  --name "AppSettings" \
  --variables \
    API_URL=https://api.example.com \
    DB_CONNECTION=<connection-string> \
  --project MyApp

# Link to Key Vault
az pipelines variable-group create \
  --name "Secrets" \
  --authorize true \
  --project MyApp \
  --variables \
    KeyVaultName=<vault-name>
```

---

## Run Pipeline

```bash
# Queue build
az pipelines run \
  --name "MyApp-CI" \
  --project MyApp \
  --branch main

# List runs
az pipelines runs list \
  --project MyApp \
  --output table

# Show run details
az pipelines runs show \
  --id <RUN_ID> \
  --project MyApp
```

---

## Key Takeaways
- YAML pipelines as code
- Multi-stage pipelines for CI/CD
- Environments for deployment tracking
- Approvals for production deployments
- Variable groups for configuration
- Artifacts for build outputs
