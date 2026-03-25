# Azure Hands-On Labs - Step-by-Step Guide

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Table of Contents

1. [Lab 1: Create Virtual Machine](#lab-1-create-virtual-machine)
2. [Lab 2: Create Storage Account](#lab-2-create-storage-account)
3. [Lab 3: Deploy Azure Kubernetes Service (AKS)](#lab-3-deploy-aks)
4. [Lab 4: Docker Containerization](#lab-4-docker-containerization)
5. [Lab 5: CI/CD Pipeline with Azure DevOps](#lab-5-cicd-pipeline)
6. [Lab 6: Code Deployment Strategies](#lab-6-code-deployment)
7. [Lab 7: Azure CDN Setup](#lab-7-azure-cdn)
8. [Lab 8: Azure Database for MySQL](#lab-8-mysql-database)
9. [Lab 9: Complete Web Application Deployment](#lab-9-complete-deployment)

---

## Lab 1: Create Virtual Machine

### Prerequisites
- Azure subscription
- Azure CLI or Portal access
- SSH key pair (for Linux VM)

### Method 1: Azure Portal

#### Step 1: Navigate to Virtual Machines
1. Login to Azure Portal: https://portal.azure.com
2. Click **"Create a resource"**
3. Search for **"Virtual Machine"**
4. Click **"Create"**

#### Step 2: Basics Configuration
```
Subscription: Select your subscription
Resource Group: Click "Create new" → Enter "rg-vm-lab-001"
Virtual machine name: vm-web-server-001
Region: East US
Availability options: No infrastructure redundancy required
Security type: Standard
Image: Ubuntu Server 22.04 LTS - x64 Gen2
Size: Standard_B2s (2 vcpus, 4 GiB memory) - $30/month
```

#### Step 3: Administrator Account
```
Authentication type: SSH public key
Username: azureuser
SSH public key source: Generate new key pair
Key pair name: vm-web-server-001_key
```

#### Step 4: Inbound Port Rules
```
Public inbound ports: Allow selected ports
Select inbound ports: 
  ☑ HTTP (80)
  ☑ HTTPS (443)
  ☑ SSH (22)
```

#### Step 5: Disks
```
OS disk type: Standard SSD (locally-redundant storage)
Delete with VM: ☑ Yes
Encryption type: (Default) Encryption at-rest with platform-managed key

Data disks: Click "Create and attach a new disk"
  Name: vm-web-server-001_DataDisk_0
  Size: 128 GiB
  Disk SKU: Standard SSD
  Click "OK"
```

#### Step 6: Networking
```
Virtual network: Click "Create new"
  Name: vnet-lab-001
  Address space: 10.0.0.0/16
  
Subnet: Click "Create new"
  Name: subnet-web
  Address range: 10.0.1.0/24
  
Public IP: (new) vm-web-server-001-ip
NIC network security group: Basic
Public inbound ports: Allow selected ports (HTTP, HTTPS, SSH)
Delete NIC when VM is deleted: ☑ Yes
```

#### Step 7: Management
```
Identity:
  System assigned managed identity: ☑ Enable

Auto-shutdown:
  Enable auto-shutdown: ☑ Yes
  Shutdown time: 7:00:00 PM
  Time zone: (UTC-05:00) Eastern Time (US & Canada)
  Notification before shutdown: ☑ Yes
  Email: your-email@domain.com

Backup:
  Enable backup: ☑ Yes (Optional)
```

#### Step 8: Monitoring
```
Boot diagnostics: Enable with managed storage account
OS guest diagnostics: Off (can enable later)
```

#### Step 9: Review + Create
1. Review all settings
2. Click **"Create"**
3. Download private key when prompted
4. Wait 3-5 minutes for deployment

#### Step 10: Connect to VM
```bash
# Set permissions on private key
chmod 400 ~/Downloads/vm-web-server-001_key.pem

# Connect via SSH
ssh -i ~/Downloads/vm-web-server-001_key.pem azureuser@<PUBLIC_IP>

# Update system
sudo apt update && sudo apt upgrade -y

# Install web server
sudo apt install nginx -y

# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify
curl http://localhost
```

### Method 2: Azure CLI

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "Your-Subscription-Name"

# Create resource group
az group create \
  --name rg-vm-lab-001 \
  --location eastus

# Create virtual network
az network vnet create \
  --resource-group rg-vm-lab-001 \
  --name vnet-lab-001 \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-web \
  --subnet-prefix 10.0.1.0/24

# Create public IP
az network public-ip create \
  --resource-group rg-vm-lab-001 \
  --name vm-web-server-001-ip \
  --sku Standard \
  --allocation-method Static

# Create NSG
az network nsg create \
  --resource-group rg-vm-lab-001 \
  --name nsg-web-001

# Add NSG rules
az network nsg rule create \
  --resource-group rg-vm-lab-001 \
  --nsg-name nsg-web-001 \
  --name AllowSSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow

az network nsg rule create \
  --resource-group rg-vm-lab-001 \
  --nsg-name nsg-web-001 \
  --name AllowHTTP \
  --priority 1001 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow

az network nsg rule create \
  --resource-group rg-vm-lab-001 \
  --nsg-name nsg-web-001 \
  --name AllowHTTPS \
  --priority 1002 \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow

# Create NIC
az network nic create \
  --resource-group rg-vm-lab-001 \
  --name vm-web-server-001-nic \
  --vnet-name vnet-lab-001 \
  --subnet subnet-web \
  --public-ip-address vm-web-server-001-ip \
  --network-security-group nsg-web-001

# Create VM
az vm create \
  --resource-group rg-vm-lab-001 \
  --name vm-web-server-001 \
  --location eastus \
  --nics vm-web-server-001-nic \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --os-disk-name vm-web-server-001-osdisk \
  --os-disk-size-gb 30 \
  --storage-sku Standard_LRS

# Attach data disk
az vm disk attach \
  --resource-group rg-vm-lab-001 \
  --vm-name vm-web-server-001 \
  --name vm-web-server-001-datadisk \
  --size-gb 128 \
  --sku Standard_LRS \
  --new

# Get public IP
az vm show \
  --resource-group rg-vm-lab-001 \
  --name vm-web-server-001 \
  --show-details \
  --query publicIps \
  --output tsv

# Enable auto-shutdown
az vm auto-shutdown \
  --resource-group rg-vm-lab-001 \
  --name vm-web-server-001 \
  --time 1900 \
  --email your-email@domain.com
```

### Method 3: Azure PowerShell

```powershell
# Connect to Azure
Connect-AzAccount

# Set subscription
Set-AzContext -Subscription "Your-Subscription-Name"

# Create resource group
New-AzResourceGroup -Name "rg-vm-lab-001" -Location "EastUS"

# Create network security group rules
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "AllowSSH" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access Allow

$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
  -Name "AllowHTTP" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

# Create NSG
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName "rg-vm-lab-001" `
  -Location "EastUS" `
  -Name "nsg-web-001" `
  -SecurityRules $nsgRuleSSH,$nsgRuleHTTP

# Create subnet
$subnet = New-AzVirtualNetworkSubnetConfig `
  -Name "subnet-web" `
  -AddressPrefix "10.0.1.0/24" `
  -NetworkSecurityGroup $nsg

# Create virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName "rg-vm-lab-001" `
  -Location "EastUS" `
  -Name "vnet-lab-001" `
  -AddressPrefix "10.0.0.0/16" `
  -Subnet $subnet

# Create public IP
$pip = New-AzPublicIpAddress `
  -ResourceGroupName "rg-vm-lab-001" `
  -Location "EastUS" `
  -Name "vm-web-server-001-ip" `
  -AllocationMethod Static `
  -Sku Standard

# Create NIC
$nic = New-AzNetworkInterface `
  -ResourceGroupName "rg-vm-lab-001" `
  -Location "EastUS" `
  -Name "vm-web-server-001-nic" `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Create VM configuration
$vmConfig = New-AzVMConfig `
  -VMName "vm-web-server-001" `
  -VMSize "Standard_B2s"

# Set OS
$vmConfig = Set-AzVMOperatingSystem `
  -VM $vmConfig `
  -Linux `
  -ComputerName "vm-web-server-001" `
  -Credential (Get-Credential)

# Set image
$vmConfig = Set-AzVMSourceImage `
  -VM $vmConfig `
  -PublisherName "Canonical" `
  -Offer "0001-com-ubuntu-server-jammy" `
  -Skus "22_04-lts-gen2" `
  -Version "latest"

# Add NIC
$vmConfig = Add-AzVMNetworkInterface `
  -VM $vmConfig `
  -Id $nic.Id

# Set OS disk
$vmConfig = Set-AzVMOSDisk `
  -VM $vmConfig `
  -Name "vm-web-server-001-osdisk" `
  -CreateOption FromImage `
  -StorageAccountType Standard_LRS

# Create VM
New-AzVM `
  -ResourceGroupName "rg-vm-lab-001" `
  -Location "EastUS" `
  -VM $vmConfig

# Add data disk
$diskConfig = New-AzDiskConfig `
  -Location "EastUS" `
  -CreateOption Empty `
  -DiskSizeGB 128 `
  -SkuName Standard_LRS

$dataDisk = New-AzDisk `
  -ResourceGroupName "rg-vm-lab-001" `
  -DiskName "vm-web-server-001-datadisk" `
  -Disk $diskConfig

$vm = Get-AzVM -ResourceGroupName "rg-vm-lab-001" -Name "vm-web-server-001"
$vm = Add-AzVMDataDisk `
  -VM $vm `
  -Name "vm-web-server-001-datadisk" `
  -CreateOption Attach `
  -ManagedDiskId $dataDisk.Id `
  -Lun 0

Update-AzVM -ResourceGroupName "rg-vm-lab-001" -VM $vm
```

### Post-Deployment Tasks

#### Configure Data Disk (Linux)
```bash
# SSH to VM
ssh azureuser@<PUBLIC_IP>

# List disks
lsblk

# Partition the disk (assuming /dev/sdc)
sudo fdisk /dev/sdc
# Press: n, p, 1, Enter, Enter, w

# Format the partition
sudo mkfs.ext4 /dev/sdc1

# Create mount point
sudo mkdir /data

# Mount the disk
sudo mount /dev/sdc1 /data

# Make it permanent
echo '/dev/sdc1 /data ext4 defaults 0 0' | sudo tee -a /etc/fstab

# Verify
df -h
```

#### Install Web Application
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Create sample app
mkdir -p /data/webapp
cd /data/webapp

# Create app
cat > app.js << 'EOF'
const http = require('http');
const os = require('os');

const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end(`
    <h1>Hello from Azure VM!</h1>
    <p>Hostname: ${os.hostname()}</p>
    <p>Platform: ${os.platform()}</p>
    <p>Time: ${new Date().toISOString()}</p>
  `);
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});
EOF

# Install PM2
sudo npm install -g pm2

# Start app
pm2 start app.js --name webapp
pm2 startup
pm2 save

# Configure Nginx reverse proxy
sudo tee /etc/nginx/sites-available/webapp << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### Verification
```bash
# Test locally
curl http://localhost

# Test from outside
curl http://<PUBLIC_IP>
```

### Cleanup
```bash
# Delete resource group (deletes all resources)
az group delete --name rg-vm-lab-001 --yes --no-wait
```

---

## Lab 2: Create Storage Account

### Method 1: Azure Portal

#### Step 1: Create Storage Account
1. Go to Azure Portal
2. Click **"Create a resource"**
3. Search **"Storage account"**
4. Click **"Create"**

#### Step 2: Basics
```
Subscription: Your subscription
Resource group: Create new → "rg-storage-lab-001"
Storage account name: stlabdata001 (must be globally unique)
Region: East US
Performance: Standard
Redundancy: Locally-redundant storage (LRS)
```

#### Step 3: Advanced
```
Security:
  Require secure transfer: ☑ Enabled
  Allow Blob public access: ☑ Enabled
  Enable storage account key access: ☑ Enabled
  Default to Azure AD authorization: ☐ Disabled
  Minimum TLS version: Version 1.2
  
Hierarchical namespace: ☐ Disabled (Enable for Data Lake Gen2)
Access tier: Hot
```

#### Step 4: Networking
```
Network connectivity:
  ○ Enable public access from all networks
  
Network routing:
  Routing preference: Microsoft network routing
```

#### Step 5: Data Protection
```
Recovery:
  Enable point-in-time restore: ☐ Disabled
  Enable soft delete for blobs: ☑ Enabled (7 days)
  Enable soft delete for containers: ☑ Enabled (7 days)
  Enable soft delete for file shares: ☑ Enabled (7 days)
  
Tracking:
  Enable versioning: ☑ Enabled
  Enable blob change feed: ☐ Disabled
```

#### Step 6: Review + Create
1. Review settings
2. Click **"Create"**
3. Wait for deployment

### Method 2: Azure CLI

```bash
# Create resource group
az group create \
  --name rg-storage-lab-001 \
  --location eastus

# Create storage account
az storage account create \
  --name stlabdata001 \
  --resource-group rg-storage-lab-001 \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access true

# Enable blob versioning
az storage account blob-service-properties update \
  --account-name stlabdata001 \
  --resource-group rg-storage-lab-001 \
  --enable-versioning true

# Enable soft delete for blobs
az storage account blob-service-properties update \
  --account-name stlabdata001 \
  --resource-group rg-storage-lab-001 \
  --enable-delete-retention true \
  --delete-retention-days 7

# Get connection string
az storage account show-connection-string \
  --name stlabdata001 \
  --resource-group rg-storage-lab-001 \
  --output tsv

# Get account key
az storage account keys list \
  --account-name stlabdata001 \
  --resource-group rg-storage-lab-001 \
  --query '[0].value' \
  --output tsv
```

### Working with Blob Storage

#### Create Container
```bash
# Set environment variables
STORAGE_ACCOUNT="stlabdata001"
STORAGE_KEY=$(az storage account keys list \
  --account-name $STORAGE_ACCOUNT \
  --resource-group rg-storage-lab-001 \
  --query '[0].value' -o tsv)

# Create container
az storage container create \
  --name webapp-assets \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --public-access blob

# Create private container
az storage container create \
  --name app-data \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --public-access off
```

#### Upload Files
```bash
# Upload single file
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name webapp-assets \
  --name index.html \
  --file ./index.html \
  --content-type "text/html"

# Upload directory
az storage blob upload-batch \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --destination webapp-assets \
  --source ./public \
  --pattern "*.html"

# Upload with metadata
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name webapp-assets \
  --name logo.png \
  --file ./logo.png \
  --metadata author="John Doe" version="1.0"
```

#### Download Files
```bash
# Download single file
az storage blob download \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name webapp-assets \
  --name index.html \
  --file ./downloaded-index.html

# Download all files
az storage blob download-batch \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --source webapp-assets \
  --destination ./downloads
```

#### List and Manage Blobs
```bash
# List blobs
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name webapp-assets \
  --output table

# Copy blob
az storage blob copy start \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --destination-container app-data \
  --destination-blob backup-index.html \
  --source-container webapp-assets \
  --source-blob index.html

# Delete blob
az storage blob delete \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name webapp-assets \
  --name old-file.txt

# Set blob tier
az storage blob set-tier \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name app-data \
  --name archive-data.zip \
  --tier Cool
```

### Generate SAS Token
```bash
# Container SAS (read/write for 24 hours)
az storage container generate-sas \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --name webapp-assets \
  --permissions rwdl \
  --expiry $(date -u -d "24 hours" '+%Y-%m-%dT%H:%MZ')

# Blob SAS (read-only for 1 hour)
az storage blob generate-sas \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name webapp-assets \
  --name index.html \
  --permissions r \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ') \
  --full-uri
```

### Enable Static Website
```bash
# Enable static website hosting
az storage blob service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# Upload website files
az storage blob upload-batch \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --destination '$web' \
  --source ./website

# Get website URL
az storage account show \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-storage-lab-001 \
  --query "primaryEndpoints.web" \
  --output tsv
```

### Lifecycle Management
```bash
# Create lifecycle policy
cat > lifecycle-policy.json << 'EOF'
{
  "rules": [
    {
      "enabled": true,
      "name": "move-to-cool",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          },
          "snapshot": {
            "delete": {
              "daysAfterCreationGreaterThan": 90
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        }
      }
    }
  ]
}
EOF

# Apply lifecycle policy
az storage account management-policy create \
  --account-name $STORAGE_ACCOUNT \
  --resource-group rg-storage-lab-001 \
  --policy @lifecycle-policy.json
```

### Cleanup
```bash
az group delete --name rg-storage-lab-001 --yes --no-wait
```

---

*This document continues with Labs 3-9 covering AKS, Docker, CI/CD, Code Deployment, CDN, MySQL, and Complete Deployment...*

**© Copyright Sivakumar J**
