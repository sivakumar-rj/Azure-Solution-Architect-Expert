# Lab 26: Disaster Recovery

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Production workloads
- Understanding of RTO and RPO

## Objective
Implement disaster recovery strategies with Azure Site Recovery, backup, and geo-replication.

---

## Disaster Recovery Concepts

- **RTO (Recovery Time Objective):** Maximum acceptable downtime
- **RPO (Recovery Point Objective):** Maximum acceptable data loss
- **Backup:** Point-in-time copy of data
- **Replication:** Continuous data synchronization
- **Failover:** Switch to secondary site
- **Failback:** Return to primary site

---

## Azure Site Recovery for VMs

```bash
# Create Recovery Services vault
az backup vault create \
  --resource-group rg-dr-lab \
  --name vault-dr \
  --location eastus

# Create secondary region resources
az group create --name rg-dr-secondary --location westus

az network vnet create \
  --resource-group rg-dr-secondary \
  --name vnet-dr \
  --address-prefix 10.1.0.0/16 \
  --subnet-name subnet-default \
  --subnet-prefix 10.1.1.0/24

# Enable replication for VM
az backup protection enable-for-vm \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --vm <VM_NAME> \
  --policy-name DefaultPolicy

# Configure replication settings (via Portal)
# Go to Recovery Services vault → Site Recovery → Replicate
# 1. Source: Primary region
# 2. Target: Secondary region
# 3. Replication policy: RPO threshold, recovery points
# 4. Enable replication
```

---

## Configure Backup

### VM Backup
```bash
# Enable VM backup
az backup protection enable-for-vm \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --vm vm-prod \
  --policy-name DefaultPolicy

# Trigger on-demand backup
az backup protection backup-now \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --container-name <CONTAINER_NAME> \
  --item-name vm-prod \
  --retain-until $(date -d "+30 days" '+%d-%m-%Y')

# List recovery points
az backup recoverypoint list \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --container-name <CONTAINER_NAME> \
  --item-name vm-prod \
  --output table

# Restore VM
az backup restore restore-disks \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --container-name <CONTAINER_NAME> \
  --item-name vm-prod \
  --rp-name <RECOVERY_POINT> \
  --storage-account <STORAGE_ACCOUNT> \
  --target-resource-group rg-dr-restored
```

### SQL Database Backup
```bash
# Configure long-term retention
az sql db ltr-policy set \
  --resource-group rg-dr-lab \
  --server sqlserver-prod \
  --database appdb \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P5Y \
  --week-of-year 1

# List backups
az sql db ltr-backup list \
  --location eastus \
  --server sqlserver-prod \
  --database appdb

# Restore from backup
az sql db ltr-backup restore \
  --dest-database appdb-restored \
  --dest-server sqlserver-prod \
  --dest-resource-group rg-dr-lab \
  --backup-id <BACKUP_ID>
```

---

## Configure Geo-Replication

### SQL Database Geo-Replication
```bash
# Create secondary server
az sql server create \
  --resource-group rg-dr-secondary \
  --name sqlserver-secondary \
  --location westus \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd123!'

# Create geo-replica
az sql db replica create \
  --resource-group rg-dr-lab \
  --server sqlserver-prod \
  --name appdb \
  --partner-server sqlserver-secondary \
  --partner-resource-group rg-dr-secondary

# Failover to secondary
az sql db replica set-primary \
  --resource-group rg-dr-secondary \
  --server sqlserver-secondary \
  --name appdb

# Failback to primary
az sql db replica set-primary \
  --resource-group rg-dr-lab \
  --server sqlserver-prod \
  --name appdb
```

### Cosmos DB Multi-Region
```bash
# Add secondary region
az cosmosdb update \
  --resource-group rg-dr-lab \
  --name cosmos-prod \
  --locations regionName=eastus failoverPriority=0 \
  --locations regionName=westus failoverPriority=1

# Enable multi-region writes
az cosmosdb update \
  --resource-group rg-dr-lab \
  --name cosmos-prod \
  --enable-multiple-write-locations true

# Manual failover
az cosmosdb failover-priority-change \
  --resource-group rg-dr-lab \
  --name cosmos-prod \
  --failover-policies westus=0 eastus=1
```

### Storage Account Geo-Redundancy
```bash
# Create storage with GRS
az storage account create \
  --resource-group rg-dr-lab \
  --name stprodgrs$RANDOM \
  --location eastus \
  --sku Standard_GRS

# Upgrade to RA-GRS (read access)
az storage account update \
  --resource-group rg-dr-lab \
  --name stprodgrs$RANDOM \
  --sku Standard_RAGRS

# Initiate failover (last resort)
az storage account failover \
  --resource-group rg-dr-lab \
  --name stprodgrs$RANDOM
```

---

## Configure Traffic Manager

```bash
# Create Traffic Manager profile
az network traffic-manager profile create \
  --resource-group rg-dr-lab \
  --name tm-dr \
  --routing-method Priority \
  --unique-dns-name myapp-dr

# Add primary endpoint
az network traffic-manager endpoint create \
  --resource-group rg-dr-lab \
  --profile-name tm-dr \
  --name primary-endpoint \
  --type azureEndpoints \
  --target-resource-id <PRIMARY_APP_ID> \
  --priority 1 \
  --endpoint-status Enabled

# Add secondary endpoint
az network traffic-manager endpoint create \
  --resource-group rg-dr-lab \
  --profile-name tm-dr \
  --name secondary-endpoint \
  --type azureEndpoints \
  --target-resource-id <SECONDARY_APP_ID> \
  --priority 2 \
  --endpoint-status Enabled

# Configure health checks
az network traffic-manager profile update \
  --resource-group rg-dr-lab \
  --name tm-dr \
  --protocol HTTPS \
  --port 443 \
  --path /health \
  --interval 30 \
  --timeout 10 \
  --max-failures 3
```

---

## Implement Backup Strategy

**3-2-1 Backup Rule:**
- 3 copies of data
- 2 different media types
- 1 offsite copy

```bash
# Primary backup to Azure Backup
az backup protection enable-for-vm \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --vm vm-prod \
  --policy-name DefaultPolicy

# Secondary backup to different region
az backup vault create \
  --resource-group rg-dr-secondary \
  --name vault-dr-secondary \
  --location westus

# Export to blob storage
az backup protection backup-now \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --container-name <CONTAINER> \
  --item-name vm-prod \
  --retain-until $(date -d "+90 days" '+%d-%m-%Y')
```

---

## Test Disaster Recovery

### DR Drill Checklist
1. **Preparation:**
   - Document DR procedures
   - Identify critical systems
   - Define RTO/RPO for each system
   - Assign roles and responsibilities

2. **Test Failover:**
```bash
# Test failover (non-disruptive)
az backup restore restore-disks \
  --resource-group rg-dr-lab \
  --vault-name vault-dr \
  --container-name <CONTAINER> \
  --item-name vm-prod \
  --rp-name <RECOVERY_POINT> \
  --storage-account <STORAGE_ACCOUNT> \
  --target-resource-group rg-dr-test

# Verify application functionality
# Test database connectivity
# Validate data integrity
```

3. **Cleanup:**
```bash
# Delete test resources
az group delete --name rg-dr-test --yes
```

---

## Automate DR with Runbooks

**failover-runbook.ps1:**
```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$TrafficManagerProfile
)

# Disable primary endpoint
Set-AzTrafficManagerEndpoint `
    -ResourceGroupName $ResourceGroupName `
    -ProfileName $TrafficManagerProfile `
    -Name "primary-endpoint" `
    -Type AzureEndpoints `
    -EndpointStatus Disabled

# Enable secondary endpoint
Set-AzTrafficManagerEndpoint `
    -ResourceGroupName $ResourceGroupName `
    -ProfileName $TrafficManagerProfile `
    -Name "secondary-endpoint" `
    -Type AzureEndpoints `
    -EndpointStatus Enabled

# Send notification
Send-MailMessage `
    -To "ops@example.com" `
    -Subject "DR Failover Completed" `
    -Body "Failover to secondary region completed successfully"
```

---

## Monitor DR Readiness

```bash
# Create alert for replication health
az monitor metrics alert create \
  --resource-group rg-dr-lab \
  --name alert-replication-health \
  --scopes <VAULT_ID> \
  --condition "avg ReplicationHealth < 100" \
  --window-size 5m \
  --action <ACTION_GROUP_ID>

# Monitor backup success
az monitor metrics alert create \
  --resource-group rg-dr-lab \
  --name alert-backup-failed \
  --scopes <VAULT_ID> \
  --condition "count BackupHealth == 0" \
  --window-size 24h \
  --action <ACTION_GROUP_ID>
```

---

## DR Documentation Template

```markdown
# Disaster Recovery Plan

## Critical Systems
- Application: myapp-prod (RTO: 4h, RPO: 1h)
- Database: sqlserver-prod (RTO: 2h, RPO: 15min)
- Storage: stprod (RTO: 1h, RPO: 0)

## Failover Procedures
1. Assess situation and declare disaster
2. Notify stakeholders
3. Execute failover runbook
4. Verify secondary site functionality
5. Update DNS/Traffic Manager
6. Monitor application health

## Failback Procedures
1. Verify primary site is operational
2. Sync data from secondary to primary
3. Execute failback runbook
4. Switch traffic back to primary
5. Decommission secondary resources

## Contact Information
- DR Coordinator: name@example.com
- Azure Support: +1-800-xxx-xxxx
- Management: escalation@example.com
```

---

## Key Takeaways
- Define RTO and RPO for each workload
- Use Azure Site Recovery for VM replication
- Implement geo-redundancy for databases
- Configure Traffic Manager for failover
- Regular DR testing is critical
- Automate failover procedures
- Document everything
- Monitor replication health
- 3-2-1 backup strategy
- Test restores regularly
