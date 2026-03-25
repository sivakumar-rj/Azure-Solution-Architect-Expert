# Lab 02: App Service

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI installed
- Basic knowledge of web applications
- Git installed (optional)

## Objective
Deploy a web application to Azure App Service using multiple deployment methods.

---

## Method 1: Azure Portal

### Step 1: Create App Service Plan
1. Navigate to Azure Portal
2. Search "App Service plans" → Click "Create"
3. Fill in details:
   - Resource group: Create new → `rg-appservice-lab`
   - Name: `plan-webapp-lab`
   - Operating System: `Linux`
   - Region: `East US`
   - Pricing tier: `Basic B1`
4. Click "Review + Create" → "Create"

### Step 2: Create Web App
1. Search "App Services" → Click "Create" → "Web App"
2. **Basics tab:**
   - Resource group: `rg-appservice-lab`
   - Name: `webapp-lab-<unique-id>` (must be globally unique)
   - Publish: `Code`
   - Runtime stack: `Node 20 LTS`
   - Operating System: `Linux`
   - Region: `East US`
   - App Service Plan: `plan-webapp-lab`
3. **Deployment tab:**
   - Continuous deployment: `Disable`
4. Click "Review + Create" → "Create"

### Step 3: Deploy Sample Application
1. Go to your Web App → "Deployment Center"
2. Select "Local Git" → Save
3. Go to "Deployment credentials" → Set username/password
4. Deploy using Git:
```bash
git clone https://github.com/Azure-Samples/nodejs-docs-hello-world
cd nodejs-docs-hello-world
git remote add azure <GIT_URL_FROM_PORTAL>
git push azure main
```

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-appservice-lab-cli --location eastus

# Create App Service plan
az appservice plan create \
  --name plan-webapp-lab \
  --resource-group rg-appservice-lab-cli \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --resource-group rg-appservice-lab-cli \
  --plan plan-webapp-lab \
  --name webapp-lab-cli-$RANDOM \
  --runtime "NODE:20-lts"

# Deploy from GitHub (sample app)
az webapp deployment source config \
  --name webapp-lab-cli-$RANDOM \
  --resource-group rg-appservice-lab-cli \
  --repo-url https://github.com/Azure-Samples/nodejs-docs-hello-world \
  --branch main \
  --manual-integration

# Configure app settings
az webapp config appsettings set \
  --resource-group rg-appservice-lab-cli \
  --name webapp-lab-cli-$RANDOM \
  --settings WEBSITE_NODE_DEFAULT_VERSION="~20"

# Enable application logging
az webapp log config \
  --resource-group rg-appservice-lab-cli \
  --name webapp-lab-cli-$RANDOM \
  --application-logging filesystem \
  --level information

# Get default hostname
az webapp show \
  --resource-group rg-appservice-lab-cli \
  --name webapp-lab-cli-$RANDOM \
  --query defaultHostName -o tsv
```

---

## Method 3: PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-appservice-lab-ps" -Location "EastUS"

# Create App Service plan
New-AzAppServicePlan `
  -ResourceGroupName "rg-appservice-lab-ps" `
  -Name "plan-webapp-lab" `
  -Location "EastUS" `
  -Tier "Basic" `
  -NumberofWorkers 1 `
  -WorkerSize "Small" `
  -Linux

# Create web app
New-AzWebApp `
  -ResourceGroupName "rg-appservice-lab-ps" `
  -Name "webapp-lab-ps-$(Get-Random)" `
  -Location "EastUS" `
  -AppServicePlan "plan-webapp-lab"

# Configure runtime
Set-AzWebApp `
  -ResourceGroupName "rg-appservice-lab-ps" `
  -Name "webapp-lab-ps-*" `
  -LinuxFxVersion "NODE|20-lts"
```

---

## Advanced Configuration

### Configure Custom Domain
```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name <APP_NAME> \
  --resource-group <RG_NAME> \
  --hostname www.example.com

# Bind SSL certificate
az webapp config ssl bind \
  --certificate-thumbprint <THUMBPRINT> \
  --ssl-type SNI \
  --name <APP_NAME> \
  --resource-group <RG_NAME>
```

### Configure Deployment Slots
```bash
# Create staging slot
az webapp deployment slot create \
  --name <APP_NAME> \
  --resource-group <RG_NAME> \
  --slot staging

# Swap slots
az webapp deployment slot swap \
  --name <APP_NAME> \
  --resource-group <RG_NAME> \
  --slot staging \
  --target-slot production
```

### Scale Out
```bash
# Manual scale
az appservice plan update \
  --name plan-webapp-lab \
  --resource-group <RG_NAME> \
  --number-of-workers 3

# Auto-scale (requires Standard tier or higher)
az monitor autoscale create \
  --resource-group <RG_NAME> \
  --resource <PLAN_ID> \
  --resource-type Microsoft.Web/serverfarms \
  --name autoscale-rule \
  --min-count 1 \
  --max-count 5 \
  --count 1
```

---

## Verification Steps

1. **Test web app:**
```bash
curl https://<APP_NAME>.azurewebsites.net
```

2. **View logs:**
```bash
az webapp log tail --name <APP_NAME> --resource-group <RG_NAME>
```

3. **Check app status:**
```bash
az webapp show --name <APP_NAME> --resource-group <RG_NAME> --query state
```

---

## Troubleshooting

**Issue: App not starting**
- Check runtime version compatibility
- Review application logs in Portal
- Verify startup command in Configuration

**Issue: 502/503 errors**
- Check App Service plan resources
- Review application performance
- Verify health check endpoint

**Issue: Deployment fails**
- Verify deployment credentials
- Check build logs
- Ensure correct runtime stack

---

## Cleanup

```bash
az group delete --name rg-appservice-lab-cli --yes --no-wait
```

---

## Key Takeaways
- App Service provides managed hosting for web apps
- Supports multiple languages and frameworks
- Deployment slots enable zero-downtime deployments
- Built-in scaling and monitoring capabilities
- Pay only for App Service Plan, not per app
