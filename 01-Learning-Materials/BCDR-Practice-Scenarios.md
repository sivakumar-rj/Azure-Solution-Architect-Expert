# Business Continuity Practice Scenarios

## Scenario 1: E-Commerce Platform Migration

**Context:**
You're migrating a critical e-commerce platform to Azure. The application currently runs on-premises with:
- 3-tier architecture (web, app, database)
- 50,000 daily active users
- Peak traffic during holidays (5x normal)
- Current uptime: 99.5%
- Revenue loss: $10,000/hour during downtime

**Requirements:**
- Target: 99.99% availability
- RTO: < 5 minutes
- RPO: < 1 minute
- Support Black Friday traffic spikes
- Global customer base (US, EU, Asia)

**Your Task:**
Design a BCDR solution that meets these requirements.

**Solution Approach:**
1. Multi-region active-active deployment (East US, West Europe, Southeast Asia)
2. Azure Front Door for global load balancing
3. Azure SQL Database with active geo-replication
4. Azure Cache for Redis with geo-replication
5. Auto-scaling App Service Plans
6. Azure CDN for static content
7. Application Insights for monitoring

**Cost Estimate:** $12,000-$18,000/month

---

## Scenario 2: Healthcare Records System

**Context:**
A healthcare provider needs to migrate patient records system to Azure:
- 500 GB database (growing 10 GB/month)
- HIPAA compliance required
- 24/7 availability needed
- Zero data loss tolerance
- Must maintain audit logs for 7 years

**Requirements:**
- 99.99% availability
- RTO: < 30 minutes
- RPO: Zero data loss
- Data encryption at rest and in transit
- Immutable backups
- Private network connectivity only

**Your Task:**
Design a compliant BCDR solution.

**Solution Approach:**
1. Zone-redundant deployment in primary region
2. Azure SQL Database Business Critical (zone-redundant)
3. Geo-replica in paired region
4. Azure Backup with immutable vaults
5. Private endpoints for all services
6. Azure Site Recovery for VMs
7. Always Encrypted + TDE
8. Azure Monitor with 7-year log retention

**Cost Estimate:** $8,000-$15,000/month

---

## Scenario 3: Financial Trading Platform

**Context:**
Real-time trading platform with strict requirements:
- Sub-second latency required
- Processes 100,000 transactions/second
- Regulatory requirement: 99.99% uptime
- Must maintain transaction logs for 10 years
- Cannot lose any transaction data

**Requirements:**
- 99.99% availability
- RTO: < 1 minute (automated)
- RPO: Zero data loss
- Low latency (< 10ms)
- Compliance with financial regulations

**Your Task:**
Design an ultra-reliable BCDR solution.

**Solution Approach:**
1. Zone-redundant deployment with availability zones
2. Azure SQL Database Business Critical with zone redundancy
3. Synchronous replication within zones
4. Asynchronous geo-replication to secondary region
5. Azure Front Door with priority routing
6. ExpressRoute for low-latency connectivity
7. Azure Backup with long-term retention
8. Automated failover groups

**Cost Estimate:** $20,000-$35,000/month

---

## Scenario 4: SaaS Startup Cost Optimization

**Context:**
A startup SaaS company needs DR but has budget constraints:
- 1,000 active users
- Growing 20% monthly
- Limited budget: $2,000/month for infrastructure
- Can tolerate 1 hour downtime
- Acceptable data loss: 15 minutes

**Requirements:**
- 99.9% availability
- RTO: < 1 hour
- RPO: < 15 minutes
- Cost-optimized solution
- Ability to scale as company grows

**Your Task:**
Design a cost-effective BCDR solution.

**Solution Approach:**
1. Single region with warm standby in paired region
2. Azure App Service (Standard tier)
3. Azure SQL Database (General Purpose)
4. Cosmos DB with single-region writes
5. Azure Backup (daily)
6. Traffic Manager for failover
7. Scale secondary resources down (50% capacity)
8. Manual failover process

**Cost Estimate:** $1,500-$2,500/month

---

## Scenario 5: Media Streaming Service

**Context:**
Video streaming platform serving global audience:
- 1 million concurrent users
- 10 PB of video content
- Live streaming events
- Content in multiple regions
- Peak usage during evening hours

**Requirements:**
- 99.95% availability
- RTO: < 15 minutes
- RPO: < 30 seconds
- Global content delivery
- Low latency streaming (< 100ms)

**Your Task:**
Design a global BCDR solution for media delivery.

**Solution Approach:**
1. Multi-region active-active (3+ regions)
2. Azure Media Services in each region
3. Azure Storage with RA-GZRS
4. Azure CDN Premium (Verizon)
5. Azure Front Door for routing
6. Cosmos DB for metadata (multi-region writes)
7. Event Grid for workflow automation
8. AKS for encoding workloads

**Cost Estimate:** $25,000-$50,000/month

---

## Scenario 6: Government Agency Migration

**Context:**
Government agency migrating critical systems:
- Strict data residency requirements
- Cannot leave specific region
- 8 AM - 6 PM operation (weekdays)
- Batch processing overnight
- Compliance audits quarterly

**Requirements:**
- 99.9% availability (business hours)
- RTO: < 4 hours
- RPO: < 1 hour
- Data must stay in specific region
- Cost-conscious approach

**Your Task:**
Design a region-constrained BCDR solution.

**Solution Approach:**
1. Single region with availability zones
2. Zone-redundant services where available
3. Azure Site Recovery within region
4. Azure Backup with GRS (within geo)
5. Availability Sets for VMs
6. Azure SQL with zone redundancy
7. Scheduled backups during off-hours
8. Manual failover procedures

**Cost Estimate:** $5,000-$8,000/month

---

## Scenario 7: IoT Platform with Edge Computing

**Context:**
IoT platform collecting data from 100,000 devices:
- Real-time data ingestion
- Edge processing required
- 50 TB data/month
- Analytics and ML workloads
- Device management critical

**Requirements:**
- 99.95% availability
- RTO: < 30 minutes
- RPO: < 5 minutes
- Edge resilience
- Cloud backup

**Your Task:**
Design a hybrid edge-cloud BCDR solution.

**Solution Approach:**
1. Azure IoT Hub with zone redundancy
2. Azure IoT Edge on devices (local resilience)
3. Event Hubs for data ingestion
4. Azure Stream Analytics for processing
5. Cosmos DB for device state
6. Azure Data Lake for long-term storage
7. Multi-region IoT Hub deployment
8. Device Provisioning Service with failover

**Cost Estimate:** $10,000-$18,000/month

---

## Scenario 8: Retail Chain Point-of-Sale

**Context:**
Retail chain with 500 stores:
- Each store has local POS system
- Centralized inventory management
- Must operate during cloud outage
- Sync when connectivity restored
- Peak during weekends

**Requirements:**
- 99.9% availability
- RTO: < 2 hours (cloud)
- RPO: < 30 minutes
- Store-level resilience
- Eventual consistency acceptable

**Your Task:**
Design a distributed BCDR solution.

**Solution Approach:**
1. Azure Stack HCI at each store
2. Local SQL Server with sync to cloud
3. Azure SQL Database (cloud)
4. Azure Site Recovery for cloud VMs
5. VPN/ExpressRoute connectivity
6. Azure Backup for cloud resources
7. Store-level UPS and redundancy
8. Conflict resolution for sync

**Cost Estimate:** $15,000-$25,000/month (cloud portion)

---

## Practice Questions

### Question 1:
Your application requires 99.99% availability. Which deployment pattern should you choose?

A) Single region with availability zones  
B) Multi-region active-passive  
C) Multi-region active-active  
D) Single region with backup

**Answer:** C - Multi-region active-active provides the highest availability by distributing traffic across multiple regions.

### Question 2:
You need RPO of 5 minutes for VMs. Which service should you use?

A) Azure Backup (daily)  
B) Azure Site Recovery  
C) Storage snapshots  
D) Geo-redundant storage

**Answer:** B - Azure Site Recovery provides continuous replication with RPO of 30 seconds to 5 minutes.

### Question 3:
Your SQL database must have zero data loss within a region. What should you configure?

A) Geo-replication  
B) Zone-redundant deployment  
C) Read replicas  
D) Point-in-time restore

**Answer:** B - Zone-redundant deployment provides synchronous replication across availability zones with zero data loss.

### Question 4:
You need to reduce costs for a warm standby environment. What should you do?

A) Use smaller VM SKUs in secondary region  
B) Remove secondary region entirely  
C) Use spot instances  
D) Disable monitoring

**Answer:** A - Using smaller VM SKUs in secondary region reduces costs while maintaining warm standby capability.

### Question 5:
Your application must failover automatically within 5 minutes. Which service provides this?

A) Azure Traffic Manager  
B) Azure Front Door  
C) Azure Load Balancer  
D) Azure Application Gateway

**Answer:** B - Azure Front Door provides instant failover with health probes and automatic routing.

---

## Hands-On Labs

### Lab 1: Configure Azure Site Recovery
1. Create two VMs in different regions
2. Set up Recovery Services Vault
3. Enable replication
4. Perform test failover
5. Validate application functionality
6. Clean up test resources

### Lab 2: Implement SQL Geo-Replication
1. Create Azure SQL Database
2. Configure geo-replica in paired region
3. Set up failover group
4. Test automatic failover
5. Monitor replication lag
6. Perform failback

### Lab 3: Multi-Region App Service
1. Deploy App Service in two regions
2. Configure Azure Front Door
3. Set up health probes
4. Test automatic failover
5. Monitor traffic distribution
6. Implement custom routing rules

### Lab 4: Backup and Restore
1. Create VM with data disks
2. Configure Azure Backup
3. Perform manual backup
4. Delete VM
5. Restore from backup
6. Validate data integrity

### Lab 5: Zone-Redundant Deployment
1. Create zone-redundant App Service
2. Deploy zone-redundant SQL Database
3. Configure zone-redundant Load Balancer
4. Test zone failure scenario
5. Monitor availability metrics
6. Document findings

---

## Common Mistakes to Avoid

1. ❌ Not testing DR procedures regularly
2. ❌ Assuming automatic failover works without testing
3. ❌ Ignoring network connectivity in DR plan
4. ❌ Not documenting dependencies
5. ❌ Underestimating RTO/RPO requirements
6. ❌ Forgetting to update DNS TTL values
7. ❌ Not considering data consistency
8. ❌ Overlooking compliance requirements
9. ❌ Inadequate monitoring and alerting
10. ❌ Not having rollback procedures

---

## Exam Tips

- Know the difference between RTO, RPO, and RLO
- Understand when to use ASR vs Azure Backup
- Memorize availability SLAs for key services
- Know paired regions and their purpose
- Understand zone-redundant vs geo-redundant
- Know Traffic Manager routing methods
- Understand failover groups for SQL
- Know cost implications of each pattern
- Understand compliance requirements (HIPAA, PCI DSS)
- Know how to calculate availability percentages
