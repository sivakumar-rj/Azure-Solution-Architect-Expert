# Business Continuity & Disaster Recovery - Quick Reference Guide

## Service SLAs

| Service | Tier | SLA | Notes |
|---------|------|-----|-------|
| App Service | Basic | 99.95% | Single instance |
| App Service | Standard/Premium | 99.95% | Zone redundant available |
| Azure SQL Database | Basic/Standard | 99.99% | Single region |
| Azure SQL Database | Business Critical | 99.995% | Zone redundant |
| Virtual Machines | Single VM (Premium SSD) | 99.9% | Single instance |
| Virtual Machines | Availability Set | 99.95% | 2+ instances |
| Virtual Machines | Availability Zones | 99.99% | 2+ zones |
| Storage (LRS) | Standard | 99.9% | Local redundancy |
| Storage (ZRS) | Standard | 99.9% | Zone redundancy |
| Storage (GRS) | Standard | 99.9% (read) | Geo redundancy |
| Storage (RA-GRS) | Standard | 99.99% (read) | Read access geo |
| Cosmos DB | Single region | 99.99% | |
| Cosmos DB | Multi-region | 99.999% | Write region |
| AKS | Standard | 99.95% | With availability zones |
| Azure Front Door | Standard/Premium | 99.99% | Global service |
| Traffic Manager | All tiers | 99.99% | DNS-based |

## RPO/RTO by Service

| Service | RPO | RTO | Method |
|---------|-----|-----|--------|
| Azure Site Recovery | 30 sec - 5 min | Minutes - Hours | Continuous replication |
| Azure Backup (VM) | 24 hours | Hours | Daily backup |
| Azure Backup (SQL) | 15 minutes | Hours | Log backup |
| SQL Geo-Replication | < 5 seconds | Minutes | Async replication |
| SQL Zone-Redundant | 0 (zero) | Seconds | Sync replication |
| Storage GRS | ~15 minutes | Hours | Async replication |
| Storage RA-GRS | ~15 minutes | Minutes | Read access |
| Cosmos DB Multi-region | < 1 second | Automatic | Multi-master |
| Redis Geo-Replication | < 1 minute | Minutes | Active replication |

## Paired Regions

| Primary Region | Paired Region | Geography |
|----------------|---------------|-----------|
| East US | West US | United States |
| East US 2 | Central US | United States |
| West US 2 | West Central US | United States |
| North Europe | West Europe | Europe |
| UK South | UK West | United Kingdom |
| Southeast Asia | East Asia | Asia Pacific |
| Australia East | Australia Southeast | Australia |
| Brazil South | South Central US | Americas |
| Canada Central | Canada East | Canada |
| Japan East | Japan West | Japan |
| Korea Central | Korea South | Korea |
| France Central | France South | France |
| Germany West Central | Germany North | Germany |
| Switzerland North | Switzerland West | Switzerland |
| UAE North | UAE Central | UAE |

## Cost Comparison Matrix

| Pattern | Compute Cost | Storage Cost | Network Cost | Total (Est.) |
|---------|--------------|--------------|--------------|--------------|
| Active-Active | 200% | 200% | High | $$$$ |
| Hot Standby | 150% | 200% | Medium | $$$ |
| Warm Standby | 100% | 200% | Low | $$ |
| Cold Standby | 50% | 200% | Very Low | $ |
| Backup Only | 0% | 110% | Minimal | $ |

## Availability Calculations

### Downtime per Year
- 99% = 3.65 days
- 99.5% = 1.83 days
- 99.9% = 8.76 hours
- 99.95% = 4.38 hours
- 99.99% = 52.56 minutes
- 99.999% = 5.26 minutes

### Composite SLA Formula
**Serial (AND):** SLA₁ × SLA₂ × SLA₃  
**Parallel (OR):** 1 - [(1 - SLA₁) × (1 - SLA₂)]

**Example:**
- App Service (99.95%) + SQL (99.99%) = 0.9995 × 0.9999 = 99.94%
- Two regions (99.9% each) = 1 - [(1 - 0.999) × (1 - 0.999)] = 99.9999%

## Service Tier Requirements

### For 99.99% Availability
- ✅ Availability Zones (2+ zones)
- ✅ Multi-region active-active
- ✅ Zone-redundant services
- ✅ Premium/Business Critical tiers

### For 99.95% Availability
- ✅ Availability Sets
- ✅ Multi-region active-passive
- ✅ Standard/Premium tiers
- ✅ Hot standby

### For 99.9% Availability
- ✅ Single region with redundancy
- ✅ Warm standby
- ✅ Standard tiers
- ✅ Regular backups

## Failover Checklist

### Pre-Failover
- [ ] Verify primary region is down
- [ ] Check replication status
- [ ] Notify stakeholders
- [ ] Review runbook
- [ ] Verify secondary region health

### During Failover
- [ ] Initiate failover procedure
- [ ] Update DNS/routing
- [ ] Start stopped resources
- [ ] Validate connectivity
- [ ] Test application functionality

### Post-Failover
- [ ] Monitor performance
- [ ] Check data consistency
- [ ] Update documentation
- [ ] Communicate status
- [ ] Plan failback

## Common Commands

### Azure CLI - Site Recovery
```bash
# Test failover
az backup protection backup-now --resource-group MyRG --vault-name MyVault --container-name MyContainer --item-name MyVM

# Check replication health
az site-recovery replication-protected-item show --resource-group MyRG --vault-name MyVault --fabric-name MyFabric --protection-container MyContainer --name MyVM
```

### Azure CLI - SQL Failover
```bash
# Initiate failover
az sql failover-group set-primary --name MyFailoverGroup --resource-group MyRG --server MyServer

# Check failover group status
az sql failover-group show --name MyFailoverGroup --resource-group MyRG --server MyServer
```

### PowerShell - Backup
```powershell
# Trigger backup
Backup-AzRecoveryServicesBackupItem -WorkloadType AzureVM -Item $item -VaultId $vault.ID

# Restore VM
Restore-AzRecoveryServicesBackupItem -RecoveryPoint $rp -StorageAccountName "mystorageaccount" -StorageAccountResourceGroupName "MyRG"
```

## Monitoring Metrics

### Critical Metrics to Track
1. **Replication Health** - ASR replication status
2. **Replication Lag** - SQL geo-replication delay
3. **Backup Success Rate** - Percentage of successful backups
4. **Health Probe Status** - Front Door/Traffic Manager probes
5. **Availability** - Service uptime percentage
6. **MTTR** - Mean Time To Recover
7. **MTBF** - Mean Time Between Failures

### Alert Thresholds
- Replication lag > 5 minutes: Warning
- Replication lag > 15 minutes: Critical
- Backup failure: Critical
- Health probe failure: Critical
- Replication health degraded: Warning

## Compliance Requirements

### HIPAA
- ✅ Encryption at rest and in transit
- ✅ Audit logging (7 years)
- ✅ Access controls
- ✅ BAA with Microsoft
- ✅ Immutable backups

### PCI DSS
- ✅ Network segmentation
- ✅ Encryption of cardholder data
- ✅ Regular security testing
- ✅ Access logging
- ✅ Quarterly backups

### GDPR
- ✅ Data residency controls
- ✅ Right to be forgotten
- ✅ Data portability
- ✅ Breach notification
- ✅ Privacy by design

### SOC 2
- ✅ Access controls
- ✅ Change management
- ✅ Monitoring and alerting
- ✅ Incident response
- ✅ Regular audits

## Best Practices Summary

### Design
1. Define clear RTO/RPO per workload
2. Use paired regions for geo-redundancy
3. Implement health probes
4. Document dependencies
5. Consider compliance requirements

### Implementation
1. Automate failover where possible
2. Use infrastructure as code
3. Implement circuit breakers
4. Configure monitoring and alerts
5. Use managed services when available

### Testing
1. Test DR quarterly minimum
2. Document test results
3. Update runbooks
4. Test failback procedures
5. Validate data consistency

### Operations
1. Monitor replication health
2. Track backup success rates
3. Review and update DR plans
4. Train team on procedures
5. Conduct post-incident reviews

## Exam Tips

### Must Know
- RTO vs RPO definitions
- Availability zone vs region
- Paired regions concept
- SLA calculations
- ASR vs Azure Backup
- Failover groups for SQL
- Traffic Manager routing methods
- Zone-redundant vs geo-redundant

### Common Traps
- Confusing RTO with RPO
- Not considering network in DR
- Assuming automatic failover without configuration
- Ignoring DNS TTL in failover time
- Overlooking data consistency
- Not accounting for dependencies

### Time Management
- Read questions carefully
- Eliminate wrong answers first
- Flag uncertain questions
- Review flagged questions
- Don't spend > 2 minutes per question

## Quick Decision Tree

```
Need 99.99%+ availability?
├─ YES → Multi-region active-active or Zone-redundant
└─ NO → Continue

Need < 5 min RTO?
├─ YES → Automated failover (Front Door, Failover Groups)
└─ NO → Continue

Need zero data loss?
├─ YES → Zone-redundant or synchronous replication
└─ NO → Continue

Budget constrained?
├─ YES → Warm/Cold standby or Backup only
└─ NO → Hot standby or Active-active

Compliance requirements?
├─ YES → Check data residency, use paired regions in same geo
└─ NO → Any region combination
```

## Resource Links

- Azure Architecture Center: https://docs.microsoft.com/azure/architecture/
- Azure SLA Summary: https://azure.microsoft.com/support/legal/sla/
- Azure Paired Regions: https://docs.microsoft.com/azure/best-practices-availability-paired-regions
- Azure Site Recovery: https://docs.microsoft.com/azure/site-recovery/
- Azure Backup: https://docs.microsoft.com/azure/backup/
