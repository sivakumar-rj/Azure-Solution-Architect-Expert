# Lab 04: Azure Files

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI installed
- Windows/Linux VM or local machine
- Basic understanding of file shares

## Objective
Create and mount Azure File shares on Windows and Linux systems.

---

## Method 1: Azure Portal

### Step 1: Create Storage Account
1. Navigate to Azure Portal
2. Search "Storage accounts" → Click "Create"
3. Fill in details:
   - Resource group: Create new → `rg-files-lab`
   - Storage account name: `stfileslab123`
   - Region: `East US`
   - Performance: `Standard`
   - Redundancy: `LRS`
4. Click "Review + Create" → "Create"

### Step 2: Create File Share
1. Go to Storage Account → "File shares"
2. Click "+ File share"
3. Fill in details:
   - Name: `documents`
   - Tier: `Transaction optimized`
   - Quota: `100 GB`
4. Click "Create"

### Step 3: Upload Files
1. Click on `documents` file share
2. Click "Upload" → Select files
3. Click "Upload"

### Step 4: Get Mount Credentials
1. Click on file share → "Connect"
2. Select OS (Windows/Linux/macOS)
3. Copy the mount script

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-files-lab-cli --location eastus

# Create storage account
STORAGE_ACCOUNT="stfilescli$RANDOM"
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-files-lab-cli \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Get storage key
STORAGE_KEY=$(az storage account keys list \
  --resource-group rg-files-lab-cli \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create file share
az storage share create \
  --name documents \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --quota 100

# Create directory in file share
az storage directory create \
  --name projects \
  --share-name documents \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY

# Upload file
az storage file upload \
  --share-name documents \
  --source ./sample.txt \
  --path projects/sample.txt \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY

# List files
az storage file list \
  --share-name documents \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --output table

# Download file
az storage file download \
  --share-name documents \
  --path projects/sample.txt \
  --dest ./downloaded.txt \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY
```

---

## Method 3: PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-files-lab-ps" -Location "EastUS"

# Create storage account
$storageAccount = New-AzStorageAccount `
  -ResourceGroupName "rg-files-lab-ps" `
  -Name "stfilesps$(Get-Random)" `
  -Location "EastUS" `
  -SkuName "Standard_LRS" `
  -Kind "StorageV2"

# Get context
$ctx = $storageAccount.Context

# Create file share
New-AzStorageShare `
  -Name "documents" `
  -Context $ctx `
  -QuotaGiB 100

# Create directory
New-AzStorageDirectory `
  -ShareName "documents" `
  -Path "projects" `
  -Context $ctx

# Upload file
Set-AzStorageFileContent `
  -ShareName "documents" `
  -Source ".\sample.txt" `
  -Path "projects/sample.txt" `
  -Context $ctx
```

---

## Mount on Windows

### Using PowerShell
```powershell
# Set variables
$storageAccountName = "<STORAGE_ACCOUNT>"
$storageAccountKey = "<STORAGE_KEY>"
$fileShareName = "documents"

# Create credential
$securePassword = ConvertTo-SecureString -String $storageAccountKey -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential `
  -ArgumentList "Azure\$storageAccountName", $securePassword

# Mount as Z: drive
New-PSDrive -Name Z -PSProvider FileSystem `
  -Root "\\$storageAccountName.file.core.windows.net\$fileShareName" `
  -Credential $credential -Persist

# Verify
Get-PSDrive Z
```

### Using Command Prompt
```cmd
net use Z: \\<STORAGE_ACCOUNT>.file.core.windows.net\documents /u:Azure\<STORAGE_ACCOUNT> <STORAGE_KEY>
```

---

## Mount on Linux

### Ubuntu/Debian
```bash
# Install cifs-utils
sudo apt-get update
sudo apt-get install cifs-utils -y

# Create mount point
sudo mkdir -p /mnt/documents

# Create credentials file
sudo bash -c 'cat > /etc/smbcredentials/<STORAGE_ACCOUNT>.cred <<EOF
username=<STORAGE_ACCOUNT>
password=<STORAGE_KEY>
EOF'

# Secure credentials file
sudo chmod 600 /etc/smbcredentials/<STORAGE_ACCOUNT>.cred

# Mount file share
sudo mount -t cifs \
  //<STORAGE_ACCOUNT>.file.core.windows.net/documents \
  /mnt/documents \
  -o credentials=/etc/smbcredentials/<STORAGE_ACCOUNT>.cred,dir_mode=0777,file_mode=0777,serverino

# Verify mount
df -h | grep documents

# Persistent mount (add to /etc/fstab)
echo "//<STORAGE_ACCOUNT>.file.core.windows.net/documents /mnt/documents cifs credentials=/etc/smbcredentials/<STORAGE_ACCOUNT>.cred,dir_mode=0777,file_mode=0777,serverino 0 0" | sudo tee -a /etc/fstab
```

### RHEL/CentOS
```bash
# Install cifs-utils
sudo yum install cifs-utils -y

# Follow same steps as Ubuntu
```

---

## Configure File Share Backup

```bash
# Create Recovery Services vault
az backup vault create \
  --resource-group rg-files-lab-cli \
  --name vault-files-backup \
  --location eastus

# Enable backup for file share
az backup protection enable-for-azurefileshare \
  --vault-name vault-files-backup \
  --resource-group rg-files-lab-cli \
  --storage-account $STORAGE_ACCOUNT \
  --azure-file-share documents \
  --policy-name DefaultPolicy

# Trigger on-demand backup
az backup protection backup-now \
  --vault-name vault-files-backup \
  --resource-group rg-files-lab-cli \
  --container-name "StorageContainer;storage;rg-files-lab-cli;$STORAGE_ACCOUNT" \
  --item-name "AzureFileShare;documents" \
  --retain-until $(date -d "+30 days" '+%d-%m-%Y')
```

---

## Configure File Share Snapshots

```bash
# Create snapshot
az storage share snapshot \
  --name documents \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY

# List snapshots
az storage share list \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --include-snapshots \
  --query "[?name=='documents']" \
  --output table

# Restore from snapshot
az storage file copy start \
  --source-share documents \
  --source-path "projects/sample.txt" \
  --destination-share documents \
  --destination-path "projects/sample-restored.txt" \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY
```

---

## Configure SMB Security

```bash
# Require secure transfer (HTTPS/SMB 3.0)
az storage account update \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-files-lab-cli \
  --https-only true

# Configure minimum SMB version
az storage account file-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group rg-files-lab-cli \
  --versions "SMB3.0;SMB3.1.1" \
  --auth-methods "Kerberos"
```

---

## Verification Steps

1. **Test file operations:**
```bash
# Create test file on mounted share
echo "Test content" > /mnt/documents/test.txt

# Verify in Azure
az storage file list \
  --share-name documents \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY
```

2. **Check mount status:**
```bash
mount | grep documents
```

3. **Test performance:**
```bash
dd if=/dev/zero of=/mnt/documents/testfile bs=1M count=100
```

---

## Troubleshooting

**Issue: Mount fails on Linux**
- Install cifs-utils package
- Verify storage account key
- Check network connectivity to Azure
- Ensure port 445 is not blocked

**Issue: Permission denied**
- Check dir_mode and file_mode in mount options
- Verify credentials file permissions (600)
- Ensure storage account key is correct

**Issue: Slow performance**
- Check network latency to Azure region
- Consider Premium file shares for better performance
- Verify no bandwidth throttling

**Issue: Cannot access from on-premises**
- Ensure port 445 is open (often blocked by ISPs)
- Consider using VPN or ExpressRoute
- Check firewall rules on storage account

---

## Cleanup

```bash
# Unmount (Linux)
sudo umount /mnt/documents

# Unmount (Windows)
net use Z: /delete

# Delete resources
az group delete --name rg-files-lab-cli --yes --no-wait
```

---

## Key Takeaways
- Azure Files provides SMB and NFS file shares
- Mountable on Windows, Linux, and macOS
- Supports standard file operations
- Built-in backup and snapshot capabilities
- Can be used with Azure File Sync for hybrid scenarios
- Premium tier available for high-performance workloads
