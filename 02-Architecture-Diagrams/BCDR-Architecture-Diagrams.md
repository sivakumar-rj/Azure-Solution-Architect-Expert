# Business Continuity & Disaster Recovery Architecture Diagrams

## Diagram 1: E-Commerce Multi-Region Active-Active

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure Front Door                              │
│                    (Global Load Balancer)                            │
│                  Health Probes + Auto Failover                       │
└────────────┬────────────────────────────────────┬────────────────────┘
             │                                    │
             ▼                                    ▼
┌────────────────────────────┐      ┌────────────────────────────┐
│   PRIMARY REGION (East US) │      │ SECONDARY REGION (West EU) │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │  App Service Plan    │ │      │  │  App Service Plan    │ │
│  │  (Premium P3V3)      │ │      │  │  (Premium P3V3)      │ │
│  │  - Auto-scale 3-10   │ │      │  │  - Auto-scale 3-10   │ │
│  │  - Zone Redundant    │ │      │  │  - Zone Redundant    │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Azure SQL Database   │ │◄────►│  │ Azure SQL Database   │ │
│  │ (Business Critical)  │ │      │  │ (Geo-Replica)        │ │
│  │ - Zone Redundant     │ │      │  │ - Read-Only          │ │
│  │ - Auto-failover      │ │      │  │ - Auto-failover      │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Redis Cache Premium  │ │◄────►│  │ Redis Cache Premium  │ │
│  │ - Geo-replication    │ │      │  │ - Geo-replica        │ │
│  │ - Zone Redundant     │ │      │  │ - Zone Redundant     │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Storage Account      │ │◄────►│  │ Storage Account      │ │
│  │ (RA-GRS)             │ │      │  │ (Read Access)        │ │
│  │ - Blob, Queue, Table │ │      │  │ - Automatic Sync     │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ Application Insights │ │      │  │ Application Insights │ │
│  │ Log Analytics        │ │      │  │ Log Analytics        │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
└────────────────────────────┘      └────────────────────────────┘

Metrics:
- Availability: 99.99%
- RTO: < 5 minutes (automatic)
- RPO: < 1 minute
- Cost: ~$8,000-$15,000/month
```

## Diagram 2: Financial Services Hot Standby

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Azure Traffic Manager                             │
│                    (Priority Routing Method)                         │
│                    Health Checks Every 30s                           │
└────────────┬────────────────────────────────────┬────────────────────┘
             │ Priority 1                         │ Priority 2
             ▼                                    ▼
┌────────────────────────────┐      ┌────────────────────────────┐
│ PRIMARY (Central US)       │      │ SECONDARY (East US 2)      │
│ *** ACTIVE ***             │      │ *** HOT STANDBY ***        │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ Virtual Machines     │ │      │  │ Virtual Machines     │ │
│  │ - 3x Web Tier (D4v5) │ │      │  │ - Stopped/Allocated  │ │
│  │ - 2x App Tier (D8v5) │ │      │  │ - ASR Replicated     │ │
│  │ - Availability Set   │ │      │  │ - Ready to Start     │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Azure SQL MI         │ │      │  │ Azure SQL MI         │ │
│  │ (Business Critical)  │◄─────►│  │ (Geo-Replica)        │ │
│  │ - Active             │ │ Sync │  │ - Read-Only          │ │
│  │ - 4 vCores           │ │      │  │ - 4 vCores           │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Recovery Services    │ │      │  │ Recovery Services    │ │
│  │ Vault                │ │      │  │ Vault                │ │
│  │ - Daily Backups      │ │      │  │ - ASR Target         │ │
│  │ - 30 Day Retention   │ │      │  │ - Failover Ready     │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ ExpressRoute         │ │      │  │ ExpressRoute         │ │
│  │ (1 Gbps)             │ │      │  │ (1 Gbps)             │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
└────────────────────────────┘      └────────────────────────────┘
             │                                    │
             └────────────┬───────────────────────┘
                          ▼
                ┌──────────────────┐
                │  On-Premises DC  │
                │  - Core Banking  │
                │  - Compliance    │
                └──────────────────┘

Metrics:
- Availability: 99.95%
- RTO: < 4 hours (manual failover)
- RPO: < 15 minutes
- Cost: ~$5,000-$8,000/month
```

## Diagram 3: SaaS Application Warm Standby

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Azure Front Door                                │
│                   + Web Application Firewall                         │
│                   + Azure CDN Integration                            │
└────────────┬────────────────────────────────────┬────────────────────┘
             │                                    │
             ▼                                    ▼
┌────────────────────────────┐      ┌────────────────────────────┐
│ PRIMARY (West US 2)        │      │ SECONDARY (East US)        │
│ *** PRODUCTION ***         │      │ *** WARM STANDBY ***       │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ AKS Cluster          │ │      │  │ AKS Cluster          │ │
│  │ - 5 nodes (D4s_v5)   │ │      │  │ - 2 nodes (D4s_v5)   │ │
│  │ - Auto-scale 3-10    │ │      │  │ - Manual scale       │ │
│  │ - Zone Redundant     │ │      │  │ - Single Zone        │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Cosmos DB            │ │◄────►│  │ Cosmos DB            │ │
│  │ (Multi-region Write) │ │      │  │ (Read Region)        │ │
│  │ - 10,000 RU/s        │ │ Sync │  │ - 5,000 RU/s         │ │
│  │ - Session Consistency│ │      │  │ - Automatic Failover │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Container Registry   │ │      │  │ Container Registry   │ │
│  │ (Premium)            │◄─────►│  │ (Geo-Replicated)     │ │
│  │ - Geo-replication    │ │      │  │ - Read-Only          │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Application Gateway  │ │      │  │ Application Gateway  │ │
│  │ - WAF Enabled        │ │      │  │ - WAF Enabled        │ │
│  │ - SSL Termination    │ │      │  │ - SSL Termination    │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ Key Vault            │ │      │  │ Key Vault            │ │
│  │ - Secrets            │ │      │  │ - Replicated         │ │
│  │ - Certificates       │ │      │  │ - Read-Only          │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
└────────────────────────────┘      └────────────────────────────┘

Metrics:
- Availability: 99.9%
- RTO: < 1 hour (scale up secondary)
- RPO: < 5 minutes
- Cost: ~$3,000-$6,000/month
```

## Diagram 4: Healthcare Zone-Redundant + Geo-Replication

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Azure Front Door Premium                          │
│              + Private Link + DDoS Protection                        │
└────────────┬────────────────────────────────────┬────────────────────┘
             │                                    │
             ▼                                    ▼
┌────────────────────────────┐      ┌────────────────────────────┐
│ PRIMARY (East US)          │      │ SECONDARY (West US)        │
│ *** ZONE-REDUNDANT ***     │      │ *** GEO-REPLICA ***        │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ Availability Zones   │ │      │  │ Recovery Services    │ │
│  │ ┌─────┬─────┬─────┐  │ │      │  │ Vault                │ │
│  │ │ AZ1 │ AZ2 │ AZ3 │  │ │      │  │ - ASR Replication    │ │
│  │ └──┬──┴──┬──┴──┬──┘  │ │      │  │ - Backup Target      │ │
│  │    │     │     │     │ │      │  └──────────────────────┘ │
│  │  ┌─▼─┐ ┌─▼─┐ ┌─▼─┐  │ │      │                            │
│  │  │VM │ │VM │ │VM │  │ │      │  ┌──────────────────────┐ │
│  │  │Set│ │Set│ │Set│  │ │      │  │ Azure SQL Database   │ │
│  │  └───┘ └───┘ └───┘  │ │      │  │ (Geo-Replica)        │ │
│  └──────────┬───────────┘ │      │  │ - Read-Only          │ │
│             │              │      │  │ - Failover Group     │ │
│  ┌──────────▼───────────┐ │      │  └──────────────────────┘ │
│  │ Azure SQL Database   │ │      │                            │
│  │ (Zone-Redundant)     │◄─────►│  ┌──────────────────────┐ │
│  │ - Business Critical  │ │ Sync │  │ Storage Account      │ │
│  │ - Always Encrypted   │ │      │  │ (GRS)                │ │
│  │ - TDE Enabled        │ │      │  │ - Backup Data        │ │
│  └──────────┬───────────┘ │      │  │ - Immutable Vault    │ │
│             │              │      │  └──────────────────────┘ │
│  ┌──────────▼───────────┐ │      │                            │
│  │ Azure Backup         │ │      │  ┌──────────────────────┐ │
│  │ (Immutable Vault)    │◄─────►│  │ Backup Vault         │ │
│  │ - Soft Delete        │ │      │  │ (GRS)                │ │
│  │ - 90 Day Retention   │ │      │  │ - Cross-Region       │ │
│  └──────────┬───────────┘ │      │  └──────────────────────┘ │
│             │              │      │                            │
│  ┌──────────▼───────────┐ │      │                            │
│  │ Private Endpoints    │ │      │  ┌──────────────────────┐ │
│  │ - SQL                │ │      │  │ Private Endpoints    │ │
│  │ - Storage            │ │      │  │ - SQL                │ │
│  │ - Key Vault          │ │      │  │ - Storage            │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
│                            │      │                            │
│  ┌──────────────────────┐ │      │                            │
│  │ Azure Monitor        │ │      │  ┌──────────────────────┐ │
│  │ - Alerts             │ │      │  │ Azure Monitor        │ │
│  │ - Metrics            │ │      │  │ - Alerts             │ │
│  │ - Logs (HIPAA)       │ │      │  │ - Metrics            │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
└────────────────────────────┘      └────────────────────────────┘

Metrics:
- Availability: 99.99%
- RTO: < 30 minutes
- RPO: Zero data loss (synchronous in zone)
- Compliance: HIPAA, HITRUST
- Cost: ~$10,000-$20,000/month
```

## Diagram 5: Media Streaming Global Distribution

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Azure CDN Premium                               │
│                   (Verizon/Microsoft)                                │
│              Global Edge Locations (100+)                            │
└────────────┬────────────────────────────────────┬────────────────────┘
             │                                    │
             ▼                                    ▼
┌────────────────────────────┐      ┌────────────────────────────┐
│ PRIMARY (West US 2)        │      │ SECONDARY (North Europe)   │
│                            │      │                            │
│  ┌──────────────────────┐ │      │  ┌──────────────────────┐ │
│  │ Media Services       │ │      │  │ Media Services       │ │
│  │ - Encoding           │ │      │  │ - Encoding           │ │
│  │ - Streaming Endpoint │ │      │  │ - Streaming Endpoint │ │
│  │ - Live Events        │ │      │  │ - Live Events        │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Storage (RA-GZRS)    │ │      │  │ Storage (RA-GZRS)    │ │
│  │ - Hot Tier (Active)  │◄─────►│  │ - Hot Tier (Active)  │ │
│  │ - Cool Tier (Archive)│ │ Sync │  │ - Cool Tier (Archive)│ │
│  │ - Blob Versioning    │ │      │  │ - Blob Versioning    │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ AKS (Encoding Jobs)  │ │      │  │ AKS (Encoding Jobs)  │ │
│  │ - GPU Nodes          │ │      │  │ - GPU Nodes          │ │
│  │ - KEDA Auto-scale    │ │      │  │ - KEDA Auto-scale    │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Event Grid           │ │      │  │ Event Grid           │ │
│  │ - Upload Events      │ │      │  │ - Upload Events      │ │
│  │ - Encoding Complete  │ │      │  │ - Encoding Complete  │ │
│  └──────────┬───────────┘ │      │  └──────────┬───────────┘ │
│             │              │      │             │              │
│  ┌──────────▼───────────┐ │      │  ┌──────────▼───────────┐ │
│  │ Cosmos DB            │ │      │  │ Cosmos DB            │ │
│  │ (Multi-region Write) │◄─────►│  │ (Multi-region Write) │ │
│  │ - Metadata           │ │      │  │ - Metadata           │ │
│  └──────────────────────┘ │      │  └──────────────────────┘ │
└────────────────────────────┘      └────────────────────────────┘
             │                                    │
             └────────────┬───────────────────────┘
                          ▼
              ┌────────────────────────┐
              │  Additional Regions    │
              │  - Southeast Asia      │
              │  - Brazil South        │
              │  - Australia East      │
              └────────────────────────┘

Metrics:
- Availability: 99.95%
- RTO: < 15 minutes
- RPO: < 30 seconds
- Global Latency: < 50ms
- Cost: ~$15,000-$40,000/month
```

## Diagram 6: Backup Strategy Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BACKUP TIERS & RETENTION                          │
└─────────────────────────────────────────────────────────────────────┘

Tier 1: Critical (RTO < 4 hours, RPO < 15 min)
┌────────────────────────────────────────────────────────────────┐
│ Azure Site Recovery (Continuous Replication)                   │
│ ├─ VMs: Every 30 seconds                                       │
│ ├─ Physical Servers: Every 5 minutes                           │
│ └─ Recovery Points: 24 hours                                   │
└────────────────────────────────────────────────────────────────┘

Tier 2: Important (RTO < 24 hours, RPO < 1 hour)
┌────────────────────────────────────────────────────────────────┐
│ Azure Backup (Scheduled)                                       │
│ ├─ VMs: Daily at 2 AM                                          │
│ ├─ SQL: Every 15 minutes (log backup)                          │
│ ├─ Files: Every 4 hours                                        │
│ └─ Retention: 30 days (daily), 12 weeks (weekly)              │
└────────────────────────────────────────────────────────────────┘

Tier 3: Standard (RTO < 72 hours, RPO < 24 hours)
┌────────────────────────────────────────────────────────────────┐
│ Storage Snapshots + GRS                                        │
│ ├─ Blob Snapshots: Daily                                       │
│ ├─ Disk Snapshots: Daily                                       │
│ └─ Retention: 7 days (local), 30 days (geo)                   │
└────────────────────────────────────────────────────────────────┘

Tier 4: Archive (Long-term Compliance)
┌────────────────────────────────────────────────────────────────┐
│ Azure Archive Storage                                          │
│ ├─ Monthly Full Backups                                        │
│ ├─ Immutable Storage (WORM)                                    │
│ └─ Retention: 7 years (compliance)                             │
└────────────────────────────────────────────────────────────────┘
```

## Diagram 7: Failover Decision Tree

```
                    ┌─────────────────────┐
                    │  Outage Detected    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ Is Primary Region   │
                    │   Responding?       │
                    └──────┬──────┬───────┘
                           │      │
                      YES  │      │  NO
                           │      │
                ┌──────────▼──┐   │
                │ Check Health│   │
                │   Probes    │   │
                └──────┬──────┘   │
                       │          │
                  ┌────▼────┐     │
                  │ Healthy?│     │
                  └────┬────┘     │
                       │          │
                  YES  │          │
                       │          │
              ┌────────▼──────┐   │
              │ False Alarm   │   │
              │ Continue      │   │
              │ Monitoring    │   │
              └───────────────┘   │
                                  │
                       ┌──────────▼──────────┐
                       │ Check Replication   │
                       │      Status         │
                       └──────┬──────────────┘
                              │
                   ┌──────────▼──────────┐
                   │ Is Secondary Ready? │
                   └──────┬──────┬───────┘
                          │      │
                     YES  │      │  NO
                          │      │
              ┌───────────▼──┐   │
              │ Notify       │   │
              │ Stakeholders │   │
              └───────┬──────┘   │
                      │          │
              ┌───────▼──────┐   │
              │ Initiate     │   │
              │ Failover     │   │
              └───────┬──────┘   │
                      │          │
              ┌───────▼──────┐   │
              │ Update DNS/  │   │
              │ Routing      │   │
              └───────┬──────┘   │
                      │          │
              ┌───────▼──────┐   │
              │ Validate     │   │
              │ Services     │   │
              └───────┬──────┘   │
                      │          │
              ┌───────▼──────┐   │
              │ Monitor      │   │
              │ Secondary    │   │
              └──────────────┘   │
                                 │
                      ┌──────────▼──────────┐
                      │ Emergency Procedure │
                      │ - Restore from      │
                      │   Backup            │
                      │ - Provision New     │
                      │   Resources         │
                      └─────────────────────┘
```

## Diagram 8: Cost vs Availability Trade-off

```
High │                                    ● Active-Active
     │                                   (99.99%+)
     │                              
     │                          ● Hot Standby
     │                         (99.95%)
     │                    
C    │              ● Warm Standby
O    │             (99.9%)
S    │        
T    │    ● Cold Standby
     │   (99.5%)
     │
Low  │ ● Backup Only
     │  (99%)
     │
     └────────────────────────────────────────────────
       Low                                        High
                    AVAILABILITY
                    
Legend:
● = Recommended configuration point
Cost includes: Compute + Storage + Network + Licensing
```

## Key Takeaways

1. **Multi-region active-active** provides highest availability but highest cost
2. **Zone-redundancy** protects against datacenter failures within a region
3. **Geo-replication** protects against regional disasters
4. **Backup tiers** should match business criticality
5. **Automated failover** reduces RTO significantly
6. **Regular testing** is essential for all DR plans
7. **Monitoring and alerting** enable fast incident response
8. **Cost optimization** requires balancing availability needs with budget
