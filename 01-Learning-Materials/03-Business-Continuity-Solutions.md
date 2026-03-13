# Domain 3: Design Business Continuity Solutions (10-15%)

## 3.1 Design Backup and Disaster Recovery Solutions

### Key Concepts

**RTO (Recovery Time Objective):** Maximum acceptable downtime  
**RPO (Recovery Point Objective):** Maximum acceptable data loss

**SLA Examples:**
- 99.9% = 8.76 hours downtime/year
- 99.99% = 52.56 minutes downtime/year
- 99.999% = 5.26 minutes downtime/year

### Azure Backup

**Supported Workloads:**
- Azure VMs, SQL Server, SAP HANA, Azure Files, On-premises

**Features:**
- Application-consistent backups
- Incremental backups
- Soft delete (14-day retention)
- Cross-region restore

### Azure Site Recovery (ASR)

**Scenarios:**
- Azure to Azure
- VMware to Azure
- Hyper-V to Azure
- Physical servers to Azure

**Process:**
1. Enable replication
2. Initial replication
3. Delta replication
4. Failover
5. Commit
6. Reprotect
7. Failback

## 3.2 Design High Availability Solutions

### Availability Zones
- Physically separate datacenters
- 99.99% VM uptime SLA (with 2+ VMs)

### Load Balancing Solutions

**Decision Matrix:**
```
Global HTTP/HTTPS → Azure Front Door
Global any protocol → Traffic Manager
Regional Layer 7 → Application Gateway
Regional Layer 4 → Load Balancer
```

### High Availability Patterns

**Active-Active:** All instances handle traffic  
**Active-Passive:** Primary handles traffic, secondary on standby  
**Multi-Region:** Resources in multiple regions

## Key Takeaways

✅ Define RTO and RPO requirements first  
✅ Use availability zones for highest availability  
✅ Implement Azure Backup for critical workloads  
✅ Test disaster recovery procedures regularly  
✅ Choose appropriate load balancing solution

---

**© Copyright Sivakumar J - All Rights Reserved**
