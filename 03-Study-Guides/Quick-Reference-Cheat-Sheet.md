# AZ-305 Quick Reference Cheat Sheet

## Compute Services Comparison

| Service | Use Case | Scaling | Management |
|---------|----------|---------|------------|
| VMs | Full control, legacy apps | Manual/VMSS | High |
| App Service | Web apps, APIs | Auto | Low |
| AKS | Containers, microservices | Auto | Medium |
| Functions | Event-driven, serverless | Auto | Very Low |
| Container Instances | Simple containers | Manual | Low |

## Storage Services

| Service | Type | Use Case | Redundancy |
|---------|------|----------|------------|
| Blob Storage | Object | Unstructured data | LRS/ZRS/GRS/GZRS |
| Azure Files | File share | SMB/NFS shares | LRS/ZRS/GRS/GZRS |
| Queue Storage | Queue | Message queue | LRS/ZRS/GRS/GZRS |
| Table Storage | NoSQL | Key-value store | LRS/ZRS/GRS/GZRS |
| Disk Storage | Block | VM disks | LRS/ZRS |

## Database Services

| Service | Type | Best For |
|---------|------|----------|
| SQL Database | Relational | Cloud-native apps |
| SQL Managed Instance | Relational | Lift-and-shift SQL Server |
| Cosmos DB | NoSQL | Global distribution, low latency |
| PostgreSQL/MySQL | Relational | Open-source preference |
| Azure Cache for Redis | In-memory | Caching, session store |

## Networking

**VPN Gateway SKUs:** Basic, VpnGw1-5, VpnGw1-5AZ  
**ExpressRoute:** 50Mbps - 10Gbps  
**Load Balancer:** Basic (free), Standard (paid, zone-redundant)  
**Application Gateway:** v1, v2 (auto-scale, zone-redundant)

## SLA Quick Reference

- Single VM (Premium SSD): 99.9%
- 2+ VMs (Availability Set): 99.95%
- 2+ VMs (Availability Zones): 99.99%
- App Service (Standard+): 99.95%
- SQL Database: 99.99%
- Cosmos DB (single region): 99.99%
- Cosmos DB (multi-region): 99.999%

## RBAC Roles

- **Owner:** Full access + access management
- **Contributor:** Full access, no access management
- **Reader:** View only
- **User Access Administrator:** Manage access only

## Azure Policy Effects

- **Deny:** Block resource creation/update
- **Audit:** Log non-compliant resources
- **Append:** Add fields to resource
- **Modify:** Add/update/remove tags
- **DeployIfNotExists:** Deploy if condition met
- **AuditIfNotExists:** Audit if related resource missing

## Backup Retention

- **Azure Backup:** 7-35 days (standard), up to 10 years (LTR)
- **SQL Database:** 7-35 days (PITR), up to 10 years (LTR)
- **Cosmos DB:** 30 days (continuous), 4 hours (periodic)

## Common Ports

- HTTP: 80
- HTTPS: 443
- RDP: 3389
- SSH: 22
- SQL Server: 1433
- PostgreSQL: 5432
- MySQL: 3306
- Redis: 6379

## Exam Tips

✅ Read questions carefully - look for keywords  
✅ Eliminate obviously wrong answers first  
✅ Consider cost, security, and scalability  
✅ Think about managed services vs IaaS  
✅ Remember SLAs and availability requirements  
✅ Consider regional vs global solutions  
✅ Don't overthink - choose the simplest solution that meets requirements

---

**© Copyright Sivakumar J - All Rights Reserved**
