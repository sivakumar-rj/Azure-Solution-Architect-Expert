# Lab 15: Azure DevOps Setup

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure DevOps account
- Azure subscription
- Git installed

## Objective
Set up Azure DevOps organization, project, and repositories.

---

## Create Azure DevOps Organization

1. Navigate to https://dev.azure.com
2. Sign in with Microsoft account
3. Click "Create new organization"
4. Enter organization name: `myorg-lab`
5. Select region
6. Click "Continue"

---

## Create Project

```bash
# Install Azure DevOps CLI extension
az extension add --name azure-devops

# Set default organization
az devops configure --defaults organization=https://dev.azure.com/myorg-lab

# Create project
az devops project create \
  --name "MyApp" \
  --description "Sample application project" \
  --visibility private \
  --source-control git

# List projects
az devops project list --output table
```

---

## Create Repository

```bash
# Create repository
az repos create \
  --name myapp-repo \
  --project MyApp

# Get clone URL
az repos show \
  --repository myapp-repo \
  --project MyApp \
  --query webUrl -o tsv

# Clone repository
git clone https://myorg-lab@dev.azure.com/myorg-lab/MyApp/_git/myapp-repo
cd myapp-repo

# Create sample files
echo "# MyApp" > README.md
echo "node_modules/" > .gitignore

# Commit and push
git add .
git commit -m "Initial commit"
git push origin main
```

---

## Create Service Connection

```bash
# Create Azure RM service connection
az devops service-endpoint azurerm create \
  --name "Azure-Connection" \
  --azure-rm-service-principal-id <SP_ID> \
  --azure-rm-subscription-id <SUBSCRIPTION_ID> \
  --azure-rm-subscription-name "My Subscription" \
  --azure-rm-tenant-id <TENANT_ID> \
  --project MyApp
```

---

## Configure Branch Policies

```bash
# Require pull request reviews
az repos policy approver-count create \
  --project MyApp \
  --repository-id <REPO_ID> \
  --branch main \
  --enabled true \
  --blocking true \
  --minimum-approver-count 2

# Require build validation
az repos policy build create \
  --project MyApp \
  --repository-id <REPO_ID> \
  --branch main \
  --enabled true \
  --blocking true \
  --build-definition-id <BUILD_ID> \
  --display-name "Build Validation"
```

---

## Create Work Items

```bash
# Create epic
az boards work-item create \
  --type Epic \
  --title "Implement User Authentication" \
  --project MyApp

# Create user story
az boards work-item create \
  --type "User Story" \
  --title "As a user, I want to login" \
  --project MyApp \
  --assigned-to user@example.com

# Create task
az boards work-item create \
  --type Task \
  --title "Create login API" \
  --project MyApp \
  --parent <STORY_ID>
```

---

## Configure Boards

1. Go to Boards → Backlogs
2. Create sprints
3. Configure columns
4. Set up swimlanes
5. Define team capacity

---

## Key Takeaways
- Azure DevOps provides end-to-end DevOps tools
- Projects organize code, work items, and pipelines
- Service connections enable Azure deployments
- Branch policies enforce code quality
- Work items track development progress
