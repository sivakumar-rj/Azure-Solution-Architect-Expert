# Lab 03: Storage Account

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI or Azure Storage Explorer
- Basic understanding of storage concepts

## Objective
Create and configure Azure Storage Account with Blob, File, Queue, and Table storage.

---

## Method 1: Azure Portal

### Step 1: Create Storage Account
1. Navigate to Azure Portal
2. Search "Storage accounts" → Click "Create"
3. **Basics tab:**
   - Resource group: Create new → `rg-storage-lab`
   - Storage account name: `stlabunique123` (lowercase, no hyphens)
   - Region: `East US`
   - Performance: `Standard`
   - Redundancy: `LRS (Locally-redundant storage)`
4. **Advanced tab:**
   - Security: Enable secure transfer (HTTPS)
   - Allow Blob public access: `Enabled`
   - Minimum TLS version: `Version 1.2`
5. Click "Review + Create" → "Create"

### Step 2: Create Blob Container
1. Go to Storage Account → "Containers"
2. Click "+ Container"
3. Name: `images`
4. Public access level: `Blob (anonymous read access for blobs only)`
5. Click "Create"

### Step 3: Upload Files
1. Click on `images` container
2. Click "Upload"
3. Select files → Click "Upload"

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-storage-lab-cli --location eastus

# Create storage account
az storage account create \
  --name stlabcli$RANDOM \
  --resource-group rg-storage-lab-cli \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot

# Get connection string
CONNECTION_STRING=$(az storage account show-connection-string \
  --name stlabcli$RANDOM \
  --resource-group rg-storage-lab-cli \
  --output tsv)

# Create blob container
az storage container create \
  --name images \
  --connection-string $CONNECTION_STRING \
  --public-access blob

# Upload blob
az storage blob upload \
  --container-name images \
  --name sample.txt \
  --file ./sample.txt \
  --connection-string $CONNECTION_STRING

# List blobs
az storage blob list \
  --container-name images \
  --connection-string $CONNECTION_STRING \
  --output table

# Create file share
az storage share create \
  --name fileshare \
  --quota 10 \
  --connection-string $CONNECTION_STRING

# Create queue
az storage queue create \
  --name taskqueue \
  --connection-string $CONNECTION_STRING

# Create table
az storage table create \
  --name customers \
  --connection-string $CONNECTION_STRING

# Get storage account key
az storage account keys list \
  --resource-group rg-storage-lab-cli \
  --account-name stlabcli$RANDOM \
  --query '[0].value' -o tsv
```

---

## Method 3: PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-storage-lab-ps" -Location "EastUS"

# Create storage account
$storageAccount = New-AzStorageAccount `
  -ResourceGroupName "rg-storage-lab-ps" `
  -Name "stlabps$(Get-Random)" `
  -Location "EastUS" `
  -SkuName "Standard_LRS" `
  -Kind "StorageV2"

# Get context
$ctx = $storageAccount.Context

# Create blob container
New-AzStorageContainer `
  -Name "images" `
  -Context $ctx `
  -Permission Blob

# Upload blob
Set-AzStorageBlobContent `
  -File ".\sample.txt" `
  -Container "images" `
  -Blob "sample.txt" `
  -Context $ctx

# Create file share
New-AzStorageShare `
  -Name "fileshare" `
  -Context $ctx

# Create queue
New-AzStorageQueue `
  -Name "taskqueue" `
  -Context $ctx

# Create table
New-AzStorageTable `
  -Name "customers" `
  -Context $ctx
```

---

## Working with Blob Storage

### Set Blob Tier
```bash
# Change access tier
az storage blob set-tier \
  --container-name images \
  --name sample.txt \
  --tier Cool \
  --connection-string $CONNECTION_STRING
```

### Generate SAS Token
```bash
# Generate SAS token for blob (valid for 1 hour)
az storage blob generate-sas \
  --container-name images \
  --name sample.txt \
  --permissions r \
  --expiry $(date -u -d "1 hour" '+%Y-%m-%dT%H:%MZ') \
  --connection-string $CONNECTION_STRING
```

### Enable Blob Versioning
```bash
az storage account blob-service-properties update \
  --account-name <STORAGE_ACCOUNT> \
  --resource-group <RG_NAME> \
  --enable-versioning true
```

---

## Configure Lifecycle Management

```bash
# Create lifecycle policy (JSON file)
cat > policy.json <<EOF
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
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["images/"]
        }
      }
    }
  ]
}
EOF

# Apply lifecycle policy
az storage account management-policy create \
  --account-name <STORAGE_ACCOUNT> \
  --resource-group <RG_NAME> \
  --policy @policy.json
```

---

## Configure Static Website

```bash
# Enable static website
az storage blob service-properties update \
  --account-name <STORAGE_ACCOUNT> \
  --static-website \
  --index-document index.html \
  --error-document-404-path 404.html

# Upload website files
az storage blob upload-batch \
  --destination '$web' \
  --source ./website \
  --account-name <STORAGE_ACCOUNT>

# Get website URL
az storage account show \
  --name <STORAGE_ACCOUNT> \
  --resource-group <RG_NAME> \
  --query "primaryEndpoints.web" -o tsv
```

---

## Verification Steps

1. **List containers:**
```bash
az storage container list --connection-string $CONNECTION_STRING --output table
```

2. **Download blob:**
```bash
az storage blob download \
  --container-name images \
  --name sample.txt \
  --file downloaded.txt \
  --connection-string $CONNECTION_STRING
```

3. **Check storage metrics:**
```bash
az monitor metrics list \
  --resource <STORAGE_ACCOUNT_ID> \
  --metric Transactions \
  --output table
```

---

## Troubleshooting

**Issue: Access denied**
- Verify storage account key or SAS token
- Check firewall and virtual network settings
- Ensure correct permissions on container

**Issue: Slow upload/download**
- Check network connectivity
- Consider using AzCopy for large files
- Verify storage account region proximity

**Issue: Cannot access blob publicly**
- Verify container public access level
- Check storage account "Allow Blob public access" setting
- Ensure firewall rules allow access

---

## Cleanup

```bash
az group delete --name rg-storage-lab-cli --yes --no-wait
```

---

## Key Takeaways
- Storage accounts support Blob, File, Queue, and Table storage
- Different redundancy options (LRS, GRS, ZRS, GZRS)
- Access tiers (Hot, Cool, Archive) optimize costs
- SAS tokens provide secure, time-limited access
- Lifecycle policies automate tier transitions
- Static website hosting available for Blob storage
