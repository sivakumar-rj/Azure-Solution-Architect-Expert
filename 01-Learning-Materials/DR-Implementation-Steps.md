# Disaster Recovery Implementation - Step-by-Step Guide

## Phase 1: Assessment & Planning

### Step 1: Define Business Requirements
```
1. Identify critical applications and data
2. Define RTO (Recovery Time Objective) for each workload
3. Define RPO (Recovery Point Objective) for each workload
4. Calculate acceptable downtime costs
5. Document compliance requirements
```

**Example:**
- Production Database: RTO = 1 hour, RPO = 15 minutes
- Web Application: RTO = 30 minutes, RPO = 5 minutes
- File Storage: RTO = 4 hours, RPO = 24 hours

### Step 2: Inventory Current Resources
```bash
# List all VMs
az vm list --output table

# List all databases
az sql db list --output table

# List all storage accounts
az storage account list --output table

# List all app services
az webapp list --output table
```

### Step 3: Choose DR Strategy
Based on RTO/RPO requirements:

| RTO | RPO | Strategy | Cost |
|-----|-----|----------|------|
| < 5 min | < 1 min | Active-Active | $$$$$ |
| < 1 hour | < 15 min | Hot Standby | $$$$ |
| < 4 hours | < 1 hour | Warm Standby | $$$ |
| < 24 hours | < 24 hours | Cold Standby | $$ |
| > 24 hours | > 24 hours | Backup Only | $ |

---

## Phase 2: Azure Site Recovery (ASR) Setup

### Step 1: Create Recovery Services Vault
```bash
# Create resource group in secondary region
az group create --name DR-RG --location westus2

# Create Recovery Services Vault
az backup vault create \
  --resource-group DR-RG \
  --name MyDRVault \
  --location westus2
```

### Step 2: Enable Replication for VMs
```bash
# Enable replication (via Portal is easier for first time)
# Azure Portal > Recovery Services Vault > Site Recovery > Replicate

# Or using Azure CLI
az site-recovery replication-protected-item create \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --fabric-name PrimaryFabric \
  --protection-container PrimaryContainer \
  --name MyVM \
  --policy-name ReplicationPolicy
```

### Step 3: Configure Replication Settings
```
1. Source: Primary region (e.g., East US)
2. Target: Secondary region (e.g., West US 2)
3. Target resource group: DR-RG
4. Target virtual network: DR-VNet
5. Replication policy: 
   - Recovery points: 24 hours
   - App-consistent snapshot: Every 4 hours
   - Multi-VM consistency: Enable if needed
```

### Step 4: Create Recovery Plan
```
1. Go to Recovery Services Vault > Recovery Plans
2. Click "+ Recovery Plan"
3. Name: Production-DR-Plan
4. Source: East US
5. Target: West US 2
6. Add VMs in order:
   Group 1: Database servers (start first)
   Group 2: Application servers
   Group 3: Web servers (start last)
7. Add scripts for automation (optional)
```

---

## Phase 3: Database DR Setup

### Option A: Azure SQL Database Geo-Replication

#### Step 1: Create Failover Group
```bash
# Create failover group
az sql failover-group create \
  --name MyFailoverGroup \
  --resource-group Production-RG \
  --server PrimaryServer \
  --partner-server SecondaryServer \
  --partner-resource-group DR-RG \
  --failover-policy Automatic \
  --grace-period 1

# Add database to failover group
az sql failover-group update \
  --name MyFailoverGroup \
  --resource-group Production-RG \
  --server PrimaryServer \
  --add-db MyDatabase
```

#### Step 2: Update Connection Strings
```
# Use failover group listener endpoint (doesn't change during failover)
Read-Write: MyFailoverGroup.database.windows.net
Read-Only: MyFailoverGroup.secondary.database.windows.net
```

### Option B: SQL Server on VMs with Always On

#### Step 1: Configure Always On Availability Groups
```sql
-- On Primary SQL Server
CREATE AVAILABILITY GROUP [AG_Production]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY)
FOR DATABASE [ProductionDB]
REPLICA ON 
  'PrimarySQL' WITH (ENDPOINT_URL = 'TCP://PrimarySQL:5022',
    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
    FAILOVER_MODE = AUTOMATIC),
  'SecondarySQL' WITH (ENDPOINT_URL = 'TCP://SecondarySQL:5022',
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
    FAILOVER_MODE = MANUAL);
```

---

## Phase 4: Storage DR Setup

### Step 1: Configure Geo-Redundant Storage
```bash
# Create storage account with GRS
az storage account create \
  --name mystoragedr \
  --resource-group Production-RG \
  --location eastus \
  --sku Standard_GRS \
  --kind StorageV2

# Upgrade to RA-GRS for read access
az storage account update \
  --name mystoragedr \
  --resource-group Production-RG \
  --sku Standard_RAGRS
```

### Step 2: Enable Soft Delete
```bash
# Enable soft delete for blobs
az storage account blob-service-properties update \
  --account-name mystoragedr \
  --enable-delete-retention true \
  --delete-retention-days 30

# Enable soft delete for file shares
az storage account file-service-properties update \
  --account-name mystoragedr \
  --enable-delete-retention true \
  --delete-retention-days 30
```

---

## Phase 5: Application DR Setup

### Option A: App Service Multi-Region

#### Step 1: Deploy to Secondary Region
```bash
# Create App Service in secondary region
az appservice plan create \
  --name DR-AppPlan \
  --resource-group DR-RG \
  --location westus2 \
  --sku P1V3

az webapp create \
  --name MyApp-DR \
  --resource-group DR-RG \
  --plan DR-AppPlan
```

#### Step 2: Configure Deployment Slots
```bash
# Create staging slot
az webapp deployment slot create \
  --name MyApp-DR \
  --resource-group DR-RG \
  --slot staging

# Deploy code to both regions
az webapp deployment source config-zip \
  --name MyApp-DR \
  --resource-group DR-RG \
  --src app.zip
```

### Option B: AKS Multi-Region

#### Step 1: Create AKS in Secondary Region
```bash
# Create AKS cluster
az aks create \
  --resource-group DR-RG \
  --name DR-AKS-Cluster \
  --location westus2 \
  --node-count 3 \
  --enable-managed-identity \
  --network-plugin azure \
  --zones 1 2 3
```

#### Step 2: Setup Container Registry Geo-Replication
```bash
# Enable geo-replication for ACR
az acr replication create \
  --registry MyContainerRegistry \
  --location westus2
```

---

## Phase 6: Network & Traffic Management

### Step 1: Setup Azure Front Door
```bash
# Create Front Door
az network front-door create \
  --resource-group Production-RG \
  --name MyFrontDoor \
  --backend-address myapp-primary.azurewebsites.net \
  --accepted-protocols Http Https

# Add secondary backend
az network front-door backend-pool backend add \
  --resource-group Production-RG \
  --front-door-name MyFrontDoor \
  --pool-name DefaultBackendPool \
  --address myapp-dr.azurewebsites.net \
  --priority 2
```

### Step 2: Configure Health Probes
```bash
az network front-door probe update \
  --resource-group Production-RG \
  --front-door-name MyFrontDoor \
  --name DefaultProbe \
  --path /health \
  --interval 30 \
  --protocol Https
```

### Alternative: Setup Traffic Manager
```bash
# Create Traffic Manager profile
az network traffic-manager profile create \
  --resource-group Production-RG \
  --name MyTMProfile \
  --routing-method Priority \
  --unique-dns-name myapp-tm

# Add primary endpoint
az network traffic-manager endpoint create \
  --resource-group Production-RG \
  --profile-name MyTMProfile \
  --name Primary \
  --type azureEndpoints \
  --target-resource-id /subscriptions/.../MyApp-Primary \
  --priority 1

# Add secondary endpoint
az network traffic-manager endpoint create \
  --resource-group Production-RG \
  --profile-name MyTMProfile \
  --name Secondary \
  --type azureEndpoints \
  --target-resource-id /subscriptions/.../MyApp-DR \
  --priority 2
```

---

## Phase 7: Backup Configuration

### Step 1: Configure Azure Backup for VMs
```bash
# Enable backup for VM
az backup protection enable-for-vm \
  --resource-group Production-RG \
  --vault-name MyDRVault \
  --vm MyVM \
  --policy-name DefaultPolicy
```

### Step 2: Configure SQL Backup
```bash
# Enable long-term retention
az sql db ltr-policy set \
  --resource-group Production-RG \
  --server PrimaryServer \
  --database MyDatabase \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P5Y \
  --week-of-year 1
```

### Step 3: Create Backup Policy
```bash
# Create custom backup policy
az backup policy create \
  --resource-group Production-RG \
  --vault-name MyDRVault \
  --name CustomPolicy \
  --backup-management-type AzureIaasVM \
  --policy '{
    "schedulePolicy": {
      "schedulePolicyType": "SimpleSchedulePolicy",
      "scheduleRunFrequency": "Daily",
      "scheduleRunTimes": ["2026-03-19T02:00:00Z"]
    },
    "retentionPolicy": {
      "retentionPolicyType": "LongTermRetentionPolicy",
      "dailySchedule": {"retentionDuration": {"count": 30, "durationType": "Days"}},
      "weeklySchedule": {"retentionDuration": {"count": 12, "durationType": "Weeks"}},
      "monthlySchedule": {"retentionDuration": {"count": 12, "durationType": "Months"}},
      "yearlySchedule": {"retentionDuration": {"count": 5, "durationType": "Years"}}
    }
  }'
```

---

## Phase 8: Monitoring & Alerting

### Step 1: Setup Azure Monitor Alerts
```bash
# Create action group
az monitor action-group create \
  --resource-group Production-RG \
  --name DR-Alerts \
  --short-name DRAlerts \
  --email-receiver name=Admin email=admin@company.com

# Create alert for replication health
az monitor metrics alert create \
  --resource-group Production-RG \
  --name ReplicationHealthAlert \
  --scopes /subscriptions/.../MyDRVault \
  --condition "avg ReplicationHealth < 100" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action DR-Alerts \
  --severity 2
```

### Step 2: Configure Log Analytics
```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group Production-RG \
  --workspace-name DR-Monitoring

# Enable diagnostics for resources
az monitor diagnostic-settings create \
  --resource /subscriptions/.../MyVM \
  --name VMDiagnostics \
  --workspace DR-Monitoring \
  --logs '[{"category": "Administrative", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

---

## Phase 9: Testing DR Plan

### Step 1: Test Failover (Non-Disruptive)
```bash
# Perform test failover for ASR
az site-recovery recovery-plan test-failover \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --name Production-DR-Plan \
  --failover-direction PrimaryToRecovery \
  --network-type ExistingVirtualNetwork \
  --network-id /subscriptions/.../DR-VNet
```

### Step 2: Validate Test Environment
```
1. Check VM status in DR region
2. Test application connectivity
3. Verify database replication
4. Test application functionality
5. Check data consistency
6. Validate DNS resolution
7. Test user access
```

### Step 3: Cleanup Test Resources
```bash
# Cleanup test failover
az site-recovery recovery-plan test-failover-cleanup \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --name Production-DR-Plan \
  --comments "Test completed successfully"
```

---

## Phase 10: Actual Failover Procedure

### When to Failover
- Primary region completely unavailable
- Extended outage expected (> RTO)
- Data center disaster
- Planned maintenance requiring extended downtime

### Failover Steps

#### Step 1: Verify Primary is Down
```bash
# Check resource health
az resource show \
  --ids /subscriptions/.../MyVM \
  --query "properties.provisioningState"

# Check service health
az rest --method get \
  --url "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01"
```

#### Step 2: Notify Stakeholders
```
1. Send notification to management
2. Alert operations team
3. Inform customers (if applicable)
4. Document incident start time
```

#### Step 3: Initiate Failover

**For ASR:**
```bash
# Planned failover (if primary accessible)
az site-recovery recovery-plan planned-failover \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --name Production-DR-Plan \
  --failover-direction PrimaryToRecovery

# Unplanned failover (if primary not accessible)
az site-recovery recovery-plan unplanned-failover \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --name Production-DR-Plan \
  --failover-direction PrimaryToRecovery \
  --source-site-operations Shutdown
```

**For SQL Failover Group:**
```bash
# Initiate SQL failover
az sql failover-group set-primary \
  --resource-group DR-RG \
  --server SecondaryServer \
  --name MyFailoverGroup
```

#### Step 4: Update DNS/Traffic Routing

**If using Traffic Manager:**
```bash
# Disable primary endpoint
az network traffic-manager endpoint update \
  --resource-group Production-RG \
  --profile-name MyTMProfile \
  --name Primary \
  --type azureEndpoints \
  --endpoint-status Disabled
```

**If using Front Door:**
```bash
# Disable primary backend
az network front-door backend-pool backend update \
  --resource-group Production-RG \
  --front-door-name MyFrontDoor \
  --pool-name DefaultBackendPool \
  --address myapp-primary.azurewebsites.net \
  --backend-host-header myapp-primary.azurewebsites.net \
  --disabled
```

#### Step 5: Validate Services
```bash
# Check VM status
az vm list --resource-group DR-RG --output table

# Check SQL connection
sqlcmd -S MyFailoverGroup.database.windows.net -U admin -P password -Q "SELECT @@SERVERNAME"

# Test application endpoint
curl -I https://myapp.com/health
```

#### Step 6: Monitor Performance
```bash
# Check metrics
az monitor metrics list \
  --resource /subscriptions/.../MyVM \
  --metric "Percentage CPU" \
  --start-time 2026-03-19T05:00:00Z \
  --end-time 2026-03-19T06:00:00Z
```

---

## Phase 11: Failback Procedure

### When to Failback
- Primary region fully restored
- All services tested and healthy
- Planned maintenance window scheduled

### Failback Steps

#### Step 1: Verify Primary Region Health
```bash
# Check service health
az resource list \
  --resource-group Production-RG \
  --query "[].{Name:name, Status:properties.provisioningState}"
```

#### Step 2: Synchronize Data
```bash
# For ASR - Reprotect VMs
az site-recovery replication-protected-item reprotect \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --fabric-name RecoveryFabric \
  --protection-container RecoveryContainer \
  --name MyVM
```

#### Step 3: Planned Failback
```bash
# Failback to primary
az site-recovery recovery-plan planned-failover \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --name Production-DR-Plan \
  --failover-direction RecoveryToPrimary
```

#### Step 4: Update Traffic Routing
```bash
# Re-enable primary endpoint
az network traffic-manager endpoint update \
  --resource-group Production-RG \
  --profile-name MyTMProfile \
  --name Primary \
  --endpoint-status Enabled
```

#### Step 5: Resume Normal Replication
```bash
# Commit failback
az site-recovery recovery-plan commit \
  --resource-group DR-RG \
  --vault-name MyDRVault \
  --name Production-DR-Plan
```

---

## Phase 12: Documentation & Continuous Improvement

### Step 1: Document Incident
```
1. Incident timeline
2. Root cause analysis
3. Actions taken
4. Issues encountered
5. Resolution time (actual RTO/RPO)
6. Lessons learned
```

### Step 2: Update Runbooks
```
1. Update failover procedures
2. Add new troubleshooting steps
3. Update contact information
4. Revise time estimates
5. Add automation scripts
```

### Step 3: Schedule Regular Tests
```
Quarterly: Test failover
Monthly: Review and update documentation
Weekly: Check replication health
Daily: Monitor backup success
```

---

## Quick Reference Checklist

### Pre-Disaster Checklist
- [ ] Recovery Services Vault created
- [ ] VM replication enabled and healthy
- [ ] Database geo-replication configured
- [ ] Storage accounts using GRS/RA-GRS
- [ ] Traffic Manager/Front Door configured
- [ ] Health probes working
- [ ] Backup policies configured
- [ ] Monitoring alerts set up
- [ ] DR plan documented
- [ ] Team trained on procedures
- [ ] Contact list updated
- [ ] Last DR test completed (< 90 days)

### During Disaster Checklist
- [ ] Primary region status verified
- [ ] Stakeholders notified
- [ ] Replication status checked
- [ ] Failover initiated
- [ ] DNS/routing updated
- [ ] Services validated
- [ ] Performance monitored
- [ ] Incident documented
- [ ] Customers informed

### Post-Disaster Checklist
- [ ] Primary region health verified
- [ ] Data synchronized
- [ ] Failback completed
- [ ] Normal replication resumed
- [ ] Incident report created
- [ ] Runbooks updated
- [ ] Lessons learned documented
- [ ] Team debriefing conducted

---

## Common Issues & Solutions

### Issue 1: Replication Lag High
**Solution:**
```bash
# Check network connectivity
az network watcher test-connectivity \
  --source-resource /subscriptions/.../PrimaryVM \
  --dest-resource /subscriptions/.../SecondaryVM

# Increase bandwidth or check throttling
```

### Issue 2: Failover Takes Longer Than Expected
**Solution:**
- Review recovery plan sequence
- Check for resource dependencies
- Optimize startup scripts
- Consider using smaller VM SKUs initially

### Issue 3: Data Inconsistency After Failover
**Solution:**
- Enable multi-VM consistency in ASR
- Use application-consistent snapshots
- Implement proper shutdown procedures
- Test data validation scripts

### Issue 4: DNS Not Updating
**Solution:**
```bash
# Reduce DNS TTL before failover
# Check Traffic Manager/Front Door health probes
# Verify endpoint configuration
# Clear DNS cache on clients
```

---

## Cost Optimization Tips

1. **Use smaller SKUs in DR region** (scale up during failover)
2. **Stop/deallocate VMs in warm standby** (keep disks)
3. **Use Azure Hybrid Benefit** for Windows licenses
4. **Implement auto-shutdown** for test environments
5. **Use cool/archive storage** for long-term backups
6. **Review retention policies** regularly
7. **Use reserved instances** for predictable workloads
8. **Implement lifecycle policies** for storage

---

## Exam Tips

- Know the difference between planned and unplanned failover
- Understand when to use ASR vs Azure Backup
- Remember failover group listener endpoints don't change
- Know how to calculate composite SLAs
- Understand recovery plan groups and sequencing
- Know health probe intervals affect RTO
- Remember DNS TTL impacts failover time
- Understand the difference between test, planned, and unplanned failover
