# Business Continuity & Disaster Recovery - Exam Practice Questions

## Section 1: Fundamentals (20 Questions)

### Question 1
Your company requires an application to have 99.99% availability. What is the maximum acceptable downtime per year?

A) 8.76 hours  
B) 52.56 minutes  
C) 4.38 hours  
D) 5.26 minutes

**Answer: B**  
**Explanation:** 99.99% availability allows for 52.56 minutes of downtime per year. 99.9% = 8.76 hours, 99.95% = 4.38 hours, 99.999% = 5.26 minutes.

---

### Question 2
What is the primary difference between RTO and RPO?

A) RTO measures data loss, RPO measures downtime  
B) RTO measures downtime, RPO measures data loss  
C) They are the same metric  
D) RTO is for backups, RPO is for replication

**Answer: B**  
**Explanation:** RTO (Recovery Time Objective) is the maximum acceptable downtime. RPO (Recovery Point Objective) is the maximum acceptable data loss measured in time.

---

### Question 3
Which Azure service provides continuous replication for VMs with RPO of 30 seconds?

A) Azure Backup  
B) Azure Site Recovery  
C) Geo-redundant Storage  
D) Availability Sets

**Answer: B**  
**Explanation:** Azure Site Recovery provides continuous replication with RPO as low as 30 seconds for Azure-to-Azure scenarios.

---

### Question 4
Your SQL database must survive a datacenter failure within the same region with zero data loss. What should you configure?

A) Geo-replication  
B) Zone-redundant configuration  
C) Read replicas  
D) Long-term retention

**Answer: B**  
**Explanation:** Zone-redundant configuration uses synchronous replication across availability zones within a region, providing zero data loss for zone failures.

---

### Question 5
Which storage redundancy option provides the highest durability?

A) LRS (Locally Redundant Storage)  
B) ZRS (Zone-Redundant Storage)  
C) GRS (Geo-Redundant Storage)  
D) All provide the same durability

**Answer: C**  
**Explanation:** GRS provides 16 nines (99.99999999999999%) durability by replicating data to a secondary region, protecting against regional disasters.

---

## Section 2: Design Scenarios (20 Questions)

### Question 6
You need to design a solution for a financial application that requires:
- 99.99% availability
- Zero data loss within region
- < 1 minute RTO
- Compliance with financial regulations

Which combination should you use?

A) Single region + daily backups  
B) Zone-redundant services + geo-replication  
C) Multi-region active-passive  
D) Availability Sets + LRS storage

**Answer: B**  
**Explanation:** Zone-redundant services provide zero data loss within region and high availability. Geo-replication protects against regional failures. This combination meets all requirements.

---

### Question 7
Your e-commerce site experiences 5x traffic during holidays. You need automatic scaling and global distribution. Which services should you use? (Choose 3)

A) Azure Front Door  
B) Azure Traffic Manager  
C) App Service with auto-scale  
D) Azure Load Balancer  
E) Azure CDN

**Answers: A, C, E**  
**Explanation:** Azure Front Door provides global load balancing, App Service auto-scale handles traffic spikes, and CDN delivers static content globally.

---

### Question 8
You need to minimize costs for a DR solution with RTO of 4 hours and RPO of 1 hour. Which pattern should you use?

A) Active-active multi-region  
B) Hot standby  
C) Warm standby  
D) Cold standby

**Answer: C**  
**Explanation:** Warm standby provides a balance between cost and recovery time. Resources are provisioned but scaled down, meeting the 4-hour RTO requirement at lower cost.

---

### Question 9
Your application must remain available during Azure region outage. What is the minimum number of regions required?

A) 1 region with availability zones  
B) 2 regions  
C) 3 regions  
D) Depends on the SLA

**Answer: B**  
**Explanation:** To survive a complete region outage, you need at least 2 regions. Availability zones protect against datacenter failures within a region, not regional failures.

---

### Question 10
You need to replicate 10 TB of data between regions with RPO of 15 minutes. Which solution is most appropriate?

A) Azure Site Recovery  
B) Azure Backup  
C) Storage account with GRS  
D) Azure Data Factory

**Answer: C**  
**Explanation:** GRS (Geo-Redundant Storage) automatically replicates data to a secondary region with RPO of approximately 15 minutes, ideal for large datasets.

---

## Section 3: Implementation (20 Questions)

### Question 11
You configured Azure SQL Database geo-replication. How do you enable automatic failover?

A) Configure Traffic Manager  
B) Create a failover group  
C) Enable auto-failover in database settings  
D) Use Azure Front Door

**Answer: B**  
**Explanation:** Failover groups provide automatic failover capability for Azure SQL Database, including a read-write listener endpoint that doesn't change during failover.

---

### Question 12
Your VMs are replicated using Azure Site Recovery. You need to test failover without impacting production. What should you do?

A) Perform a planned failover  
B) Perform an unplanned failover  
C) Perform a test failover  
D) Create manual snapshots

**Answer: C**  
**Explanation:** Test failover creates isolated VMs in the target region without affecting production or replication. It's specifically designed for DR testing.

---

### Question 13
You need to ensure DNS failover happens within 1 minute. What should you configure in Traffic Manager?

A) Set TTL to 60 seconds  
B) Set TTL to 300 seconds  
C) Use priority routing  
D) Enable fast failover

**Answer: A**  
**Explanation:** DNS TTL (Time To Live) determines how long DNS records are cached. Setting TTL to 60 seconds ensures clients refresh DNS within 1 minute.

---

### Question 14
Your application uses Azure Front Door. How does it detect backend failures?

A) Manual configuration  
B) Health probes  
C) Azure Monitor alerts  
D) Traffic analysis

**Answer: B**  
**Explanation:** Azure Front Door uses health probes to continuously monitor backend health and automatically routes traffic away from unhealthy backends.

---

### Question 15
You need to backup Azure VMs with application-consistent backups. Which service should you use?

A) Azure Site Recovery  
B) Azure Backup  
C) Storage snapshots  
D) Azure Data Factory

**Answer: B**  
**Explanation:** Azure Backup provides application-consistent backups for VMs using VSS (Windows) or pre/post scripts (Linux), ensuring data consistency.

---

## Section 4: Monitoring & Operations (15 Questions)

### Question 16
You need to monitor replication lag for Azure SQL geo-replication. Which metric should you track?

A) DTU percentage  
B) Replication lag in seconds  
C) Connection count  
D) Storage percentage

**Answer: B**  
**Explanation:** Replication lag in seconds shows the time delay between primary and secondary databases, critical for monitoring RPO compliance.

---

### Question 17
Your DR plan requires quarterly testing. How should you document test results?

A) Email summary to team  
B) Update runbook with lessons learned  
C) No documentation needed  
D) Store in personal notes

**Answer: B**  
**Explanation:** Runbooks should be living documents updated after each test with lessons learned, issues encountered, and procedure improvements.

---

### Question 18
You need to be alerted when Azure Site Recovery replication health degrades. What should you configure?

A) Azure Monitor alert rule  
B) Email notification  
C) Service Health alert  
D) Activity log alert

**Answer: A**  
**Explanation:** Azure Monitor alert rules can monitor ASR metrics like replication health and trigger notifications when thresholds are exceeded.

---

### Question 19
Your application failed over to secondary region. How do you monitor that all services are healthy?

A) Check Azure Portal manually  
B) Use Application Insights availability tests  
C) Wait for user complaints  
D) Check service logs

**Answer: B**  
**Explanation:** Application Insights availability tests continuously monitor application endpoints and can validate functionality after failover.

---

### Question 20
You need to track the success rate of Azure Backup jobs. Where should you look?

A) Activity Log  
B) Backup Reports in Recovery Services Vault  
C) Azure Monitor Metrics  
D) Resource Health

**Answer: B**  
**Explanation:** Backup Reports provide comprehensive analytics on backup jobs, including success rates, failures, and trends over time.

---

## Section 5: Advanced Scenarios (25 Questions)

### Question 21
You have a multi-tier application with dependencies. During failover, the database must be available before the application tier. How do you ensure this?

A) Use Traffic Manager priority routing  
B) Configure recovery plan in Azure Site Recovery  
C) Manual failover sequence  
D) Use availability sets

**Answer: B**  
**Explanation:** ASR recovery plans allow you to define failover sequence, grouping, and dependencies to ensure proper startup order.

---

### Question 22
Your application uses Azure Kubernetes Service (AKS). How do you implement multi-region DR?

A) Single AKS cluster with zone redundancy  
B) AKS clusters in multiple regions with Azure Front Door  
C) AKS with Azure Site Recovery  
D) AKS with Traffic Manager

**Answer: B**  
**Explanation:** Deploy AKS clusters in multiple regions and use Azure Front Door for global load balancing and automatic failover between regions.

---

### Question 23
You need to implement DR for Azure Functions with < 5 minute RTO. What should you do?

A) Deploy to single region with daily backups  
B) Deploy to multiple regions with Traffic Manager  
C) Use Premium plan with zone redundancy  
D) Deploy to multiple regions with Front Door

**Answer: D**  
**Explanation:** Azure Functions in multiple regions with Front Door provides instant failover (< 5 minutes) and global distribution.

---

### Question 24
Your Cosmos DB requires multi-region writes with automatic failover. What should you configure?

A) Single-region account with backups  
B) Multi-region account with automatic failover  
C) Multi-region account with manual failover  
D) Geo-redundant storage

**Answer: B**  
**Explanation:** Cosmos DB multi-region accounts with automatic failover enable writes in multiple regions and automatic failover without manual intervention.

---

### Question 25
You need to implement DR for Azure Storage with read access during primary region outage. Which redundancy should you use?

A) LRS  
B) ZRS  
C) GRS  
D) RA-GRS

**Answer: D**  
**Explanation:** RA-GRS (Read-Access Geo-Redundant Storage) provides read access to data in the secondary region even when primary is unavailable.

---

### Question 26
Your application requires zero data loss and < 1 minute RTO across regions. Which SQL Database tier should you use?

A) Basic  
B) Standard  
C) General Purpose  
D) Business Critical with failover groups

**Answer: D**  
**Explanation:** Business Critical tier with failover groups provides the lowest RTO and supports synchronous replication for zero data loss within zones.

---

### Question 27
You need to implement DR for Azure Virtual Desktop. What should you include? (Choose 3)

A) Host pools in multiple regions  
B) FSLogix profiles in geo-redundant storage  
C) Azure Site Recovery for session hosts  
D) Single region deployment  
E) Profile replication

**Answers: A, B, C**  
**Explanation:** Multi-region host pools, geo-redundant profile storage, and ASR for session hosts provide comprehensive DR for Azure Virtual Desktop.

---

### Question 28
Your application uses Azure Cache for Redis. How do you implement geo-replication?

A) Use Basic tier with backups  
B) Use Standard tier with export/import  
C) Use Premium tier with geo-replication  
D) Redis doesn't support geo-replication

**Answer: C**  
**Explanation:** Premium tier Azure Cache for Redis supports active geo-replication, allowing data replication between regions.

---

### Question 29
You need to implement DR for Azure API Management. What should you configure?

A) Single region with backups  
B) Multi-region deployment with custom domain  
C) Traffic Manager with multiple instances  
D) Azure Front Door with multiple instances

**Answer: B**  
**Explanation:** APIM supports multi-region deployment with a custom domain, providing automatic failover and global distribution.

---

### Question 30
Your application requires compliance with data residency laws. How do you implement DR without violating regulations?

A) Use global geo-replication  
B) Use paired regions within same geography  
C) Use any available region  
D) Don't implement DR

**Answer: B**  
**Explanation:** Azure paired regions are within the same geography (e.g., US, EU) to meet data residency requirements while providing DR capabilities.

---

### Question 31
You need to calculate the composite SLA for an application using App Service (99.95%) and SQL Database (99.99%). What is the composite SLA?

A) 99.99%  
B) 99.95%  
C) 99.94%  
D) 99.90%

**Answer: C**  
**Explanation:** Composite SLA = 0.9995 × 0.9999 = 0.9994 or 99.94%. When services are in series, multiply their SLAs.

---

### Question 32
Your DR plan requires immutable backups for compliance. What should you configure?

A) Azure Backup with soft delete  
B) Azure Backup with immutable vault  
C) Storage snapshots  
D) Geo-redundant storage

**Answer: B**  
**Explanation:** Immutable vaults in Azure Backup prevent deletion or modification of backups, meeting compliance requirements for WORM (Write Once Read Many) storage.

---

### Question 33
You need to implement DR for Azure Logic Apps. What is the recommended approach?

A) Export and import definitions  
B) Deploy to multiple regions with Traffic Manager  
C) Use Azure Site Recovery  
D) Manual recreation in DR region

**Answer: B**  
**Explanation:** Deploy Logic Apps to multiple regions and use Traffic Manager or Front Door for failover. Logic Apps are stateless, making multi-region deployment straightforward.

---

### Question 34
Your application uses Azure Service Bus. How do you implement geo-disaster recovery?

A) Use Basic tier with backups  
B) Use Standard tier with export/import  
C) Use Premium tier with geo-disaster recovery  
D) Service Bus doesn't support DR

**Answer: C**  
**Explanation:** Service Bus Premium tier supports geo-disaster recovery, allowing metadata replication to a secondary namespace.

---

### Question 35
You need to test your DR plan without impacting production. What is the best approach?

A) Perform actual failover during maintenance window  
B) Use test failover capabilities where available  
C) Document procedures without testing  
D) Test in development environment only

**Answer: B**  
**Explanation:** Test failover (available in ASR and other services) creates isolated test environments without impacting production or replication.

---

### Question 36
Your application requires < 10ms latency and 99.99% availability. Which deployment pattern should you use?

A) Single region with availability zones  
B) Multi-region active-active  
C) Multi-region active-passive  
D) Single region with backups

**Answer: A**  
**Explanation:** For < 10ms latency, resources must be in the same region. Availability zones provide 99.99% SLA while maintaining low latency.

---

### Question 37
You need to implement DR for Azure Synapse Analytics. What should you configure?

A) Geo-redundant storage for data  
B) Geo-restore capability  
C) Both A and B  
D) Synapse doesn't support DR

**Answer: C**  
**Explanation:** Synapse supports geo-redundant storage for data and geo-restore capability to restore to a different region.

---

### Question 38
Your DR plan requires automated failover with no manual intervention. Which services support this? (Choose 3)

A) Azure SQL Database with failover groups  
B) Azure Front Door  
C) Azure Site Recovery  
D) Azure Traffic Manager  
E) Azure Backup

**Answers: A, B, D**  
**Explanation:** SQL failover groups, Front Door, and Traffic Manager support automatic failover. ASR requires manual initiation, and Backup requires manual restore.

---

### Question 39
You need to implement DR for Azure Container Registry. What should you configure?

A) Use Basic tier with export  
B) Use Standard tier with webhooks  
C) Use Premium tier with geo-replication  
D) ACR doesn't support DR

**Answer: C**  
**Explanation:** Premium tier ACR supports geo-replication, automatically replicating container images to multiple regions.

---

### Question 40
Your application uses Azure Event Hubs. How do you implement geo-disaster recovery?

A) Use Basic tier with backups  
B) Use Standard tier with Capture  
C) Use Standard/Premium tier with geo-disaster recovery  
D) Event Hubs doesn't support DR

**Answer: C**  
**Explanation:** Event Hubs Standard and Premium tiers support geo-disaster recovery, replicating metadata to a secondary namespace.

---

## Answer Key Summary

**Section 1 (Fundamentals):** 1-B, 2-B, 3-B, 4-B, 5-C  
**Section 2 (Design):** 6-B, 7-ACE, 8-C, 9-B, 10-C  
**Section 3 (Implementation):** 11-B, 12-C, 13-A, 14-B, 15-B  
**Section 4 (Monitoring):** 16-B, 17-B, 18-A, 19-B, 20-B  
**Section 5 (Advanced):** 21-B, 22-B, 23-D, 24-B, 25-D, 26-D, 27-ABC, 28-C, 29-B, 30-B, 31-C, 32-B, 33-B, 34-C, 35-B, 36-A, 37-C, 38-ABD, 39-C, 40-C

## Scoring Guide

- 36-40 correct: Excellent - Ready for exam
- 30-35 correct: Good - Review weak areas
- 24-29 correct: Fair - More study needed
- Below 24: Review all materials thoroughly
