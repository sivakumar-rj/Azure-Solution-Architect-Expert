# AZ-305 Complete Study Guide

## 30-Day Study Plan

### Week 1: Identity, Governance & Monitoring (25-30%)

**Day 1-2: Azure AD & Identity**
- [ ] Azure AD vs AD DS
- [ ] Authentication methods (MFA, Conditional Access, PIM)
- [ ] Managed identities (System vs User-assigned)
- [ ] Service principals and app registrations
- [ ] Azure AD B2B and B2C
- [ ] Hybrid identity (Azure AD Connect)

**Day 3-4: Governance**
- [ ] Management groups and subscriptions
- [ ] Azure Policy (effects, initiatives)
- [ ] RBAC (built-in roles, custom roles)
- [ ] Resource locks
- [ ] Azure Blueprints
- [ ] Cost Management and budgets

**Day 5-7: Monitoring & Logging**
- [ ] Azure Monitor (metrics, logs, alerts)
- [ ] Log Analytics workspaces
- [ ] Application Insights
- [ ] Network Watcher
- [ ] Azure Advisor
- [ ] Service Health

**Practice:** 20 questions on Identity & Governance

---

### Week 2: Data Storage Solutions (25-30%)

**Day 8-9: Storage Accounts**
- [ ] Storage account types (v1, v2, Blob, File)
- [ ] Performance tiers (Standard, Premium)
- [ ] Redundancy options (LRS, ZRS, GRS, GZRS, RA-GRS)
- [ ] Access tiers (Hot, Cool, Archive)
- [ ] Blob types (Block, Append, Page)
- [ ] Azure Files (SMB, NFS, File Sync)
- [ ] Storage security (SAS, stored access policies, encryption)

**Day 10-11: Databases**
- [ ] Azure SQL Database (DTU vs vCore, elastic pools)
- [ ] SQL Managed Instance
- [ ] Cosmos DB (consistency levels, partition keys, APIs)
- [ ] PostgreSQL/MySQL (Single Server vs Flexible Server)
- [ ] Azure Cache for Redis
- [ ] Azure Synapse Analytics

**Day 12-14: Data Integration**
- [ ] Azure Data Factory
- [ ] Azure Databricks
- [ ] Event Hubs vs Event Grid vs Service Bus
- [ ] Data Lake Storage Gen2
- [ ] Azure Stream Analytics

**Practice:** 25 questions on Data Storage

---

### Week 3: Business Continuity & Infrastructure (40-45%)

**Day 15-16: Backup & DR**
- [ ] Azure Backup (MARS, MABS, Azure Backup Server)
- [ ] Recovery Services Vault
- [ ] Azure Site Recovery
- [ ] Backup policies and retention
- [ ] Cross-region restore
- [ ] Soft delete

**Day 17-18: High Availability**
- [ ] Availability Sets vs Availability Zones
- [ ] VM Scale Sets
- [ ] Load Balancer (Basic vs Standard)
- [ ] Application Gateway (v1 vs v2, WAF)
- [ ] Traffic Manager
- [ ] Azure Front Door
- [ ] SLA calculations

**Day 19-21: Compute Solutions**
- [ ] VM sizing and families
- [ ] Azure App Service (plans, deployment slots)
- [ ] Azure Functions (consumption, premium, dedicated)
- [ ] Azure Container Instances
- [ ] Azure Kubernetes Service (AKS)
- [ ] Azure Batch
- [ ] Virtual Desktop

**Practice:** 30 questions on Compute & HA

---

### Week 4: Networking & Containers (30-35%)

**Day 22-23: Networking**
- [ ] Virtual Networks (subnets, NSGs, ASGs)
- [ ] VNet peering (regional, global)
- [ ] VPN Gateway (site-to-site, point-to-site)
- [ ] ExpressRoute
- [ ] Private Link and Private Endpoints
- [ ] Service Endpoints
- [ ] Azure Firewall vs NSG vs WAF
- [ ] Azure DNS (public, private)
- [ ] Network Watcher

**Day 24-25: Containers & Microservices**
- [ ] Docker fundamentals
- [ ] Azure Container Registry (ACR)
- [ ] AKS architecture and networking
- [ ] AKS node pools and scaling
- [ ] AKS security (Azure AD, RBAC, network policies)
- [ ] Service mesh concepts
- [ ] API Management

**Day 26-28: Application Architecture**
- [ ] Microservices patterns
- [ ] Event-driven architecture
- [ ] Message queuing (Service Bus, Event Grid, Event Hubs)
- [ ] Caching strategies
- [ ] CDN
- [ ] API Management policies

**Practice:** 25 questions on Networking & Containers

---

### Days 29-30: Review & Practice Exams

**Day 29:**
- [ ] Review all weak areas
- [ ] Complete 100-question practice exam
- [ ] Review incorrect answers
- [ ] Update notes

**Day 30:**
- [ ] Final review of cheat sheets
- [ ] Complete second practice exam
- [ ] Relax and prepare mentally

---

## Study Techniques

### Active Recall
- Don't just read - test yourself
- Use flashcards for key concepts
- Explain concepts out loud
- Teach someone else

### Spaced Repetition
- Review Day 1 material on Days 3, 7, 14, 28
- Focus more time on weak areas
- Use Anki or similar tools

### Hands-On Practice
- Create Azure free account
- Build sample architectures
- Break things and fix them
- Document your learnings

---

## Key Decision Trees

### Compute Service Selection
```
Need full OS control? 
├─ Yes → Virtual Machines
└─ No → Need containers?
    ├─ Yes → Need orchestration?
    │   ├─ Yes → AKS
    │   └─ No → Container Instances
    └─ No → Web app?
        ├─ Yes → App Service
        └─ No → Event-driven?
            ├─ Yes → Functions
            └─ No → Batch → Azure Batch
```

### Storage Selection
```
What type of data?
├─ Unstructured (files, images) → Blob Storage
├─ File shares (SMB/NFS) → Azure Files
├─ Relational data → SQL Database/Managed Instance
├─ NoSQL → Cosmos DB
├─ Key-value → Table Storage or Redis
├─ Messages → Queue Storage or Service Bus
└─ Big data → Data Lake Storage Gen2
```

### Networking Connectivity
```
Connect to Azure?
├─ Internet → Public IP + NSG
├─ On-premises → Encrypted?
│   ├─ Yes → VPN Gateway
│   └─ No (dedicated) → ExpressRoute
├─ Between VNets → VNet Peering
└─ Private access to PaaS → Private Link
```

### High Availability Strategy
```
SLA requirement?
├─ 99.9% → Single VM (Premium SSD)
├─ 99.95% → Availability Set (2+ VMs)
├─ 99.99% → Availability Zones (2+ VMs)
└─ 99.99%+ → Multi-region + Traffic Manager/Front Door
```

---

## Common Exam Patterns

### Pattern 1: Cost Optimization
**Question:** "Most cost-effective solution..."
**Look for:**
- Reserved instances vs pay-as-you-go
- Spot VMs for non-critical workloads
- Auto-scaling to match demand
- Archive tier for infrequently accessed data
- Serverless options (Functions, Logic Apps)

### Pattern 2: Security Requirements
**Question:** "Ensure secure access..."
**Look for:**
- Private endpoints for PaaS services
- Managed identities (no credentials in code)
- Azure AD authentication
- Network isolation (NSGs, Azure Firewall)
- Encryption at rest and in transit

### Pattern 3: High Availability
**Question:** "Ensure 99.99% availability..."
**Look for:**
- Availability Zones (not just Availability Sets)
- Multi-region deployment
- Load balancing across zones/regions
- Geo-redundant storage
- Automatic failover

### Pattern 4: Disaster Recovery
**Question:** "RPO of 1 hour, RTO of 4 hours..."
**Look for:**
- Azure Site Recovery for VMs
- Geo-replication for databases
- Backup frequency matching RPO
- Automated failover processes

### Pattern 5: Hybrid Scenarios
**Question:** "Integrate on-premises with Azure..."
**Look for:**
- ExpressRoute for dedicated connectivity
- VPN Gateway for encrypted connectivity
- Azure AD Connect for identity sync
- Azure Arc for hybrid management
- Azure File Sync for file synchronization

---

## Memory Aids

### Storage Redundancy (LRS → GZRS)
**L**ocal → **Z**one → **G**eo → **G**eo-**Z**one
- LRS: 3 copies, same datacenter (11 nines)
- ZRS: 3 copies, 3 zones (12 nines)
- GRS: 6 copies, 2 regions (16 nines)
- GZRS: 6 copies, zones + regions (16 nines)

### Load Balancing Services (Remember: LATF)
- **L**oad Balancer: Layer 4, regional
- **A**pplication Gateway: Layer 7, regional, WAF
- **T**raffic Manager: DNS-based, global
- **F**ront Door: Layer 7, global, CDN

### Database Consistency (Cosmos DB: SBECS)
- **S**trong: Linearizability
- **B**ounded Staleness: Lag guarantee
- **E**ventual: Lowest latency
- **C**onsistent Prefix: Order guarantee
- **S**ession: Read your writes

### VM Families (Remember: DAFNE)
- **D**-series: General purpose
- **A**-series: Entry-level
- **F**-series: Compute optimized
- **N**-series: GPU
- **E**-series: Memory optimized

---

## Pre-Exam Checklist

**One Week Before:**
- [ ] Complete all practice exams
- [ ] Review all incorrect answers
- [ ] Hands-on lab for weak areas
- [ ] Review architecture diagrams

**One Day Before:**
- [ ] Review cheat sheets
- [ ] Light review only (no cramming)
- [ ] Prepare exam environment
- [ ] Get good sleep

**Exam Day:**
- [ ] Arrive 15 minutes early (online: test equipment)
- [ ] Read questions carefully
- [ ] Flag difficult questions for review
- [ ] Manage time (2 minutes per question)
- [ ] Review flagged questions

---

## Exam Strategy

### Time Management
- Total time: 120 minutes
- Questions: ~50-60
- Time per question: ~2 minutes
- Reserve 15 minutes for review

### Question Approach
1. Read the entire question
2. Identify key requirements
3. Eliminate wrong answers
4. Choose best remaining option
5. Flag if unsure, move on

### Keywords to Watch
- **Most cost-effective** → Cheapest option
- **Minimize administrative effort** → Managed service
- **Highest availability** → Multi-zone/region
- **Secure** → Private endpoints, managed identity
- **Scalable** → Auto-scaling, serverless
- **Quickly** → Existing service, not custom

---

## Resources

### Official Microsoft
- [ ] Microsoft Learn AZ-305 path
- [ ] Azure documentation
- [ ] Azure Architecture Center
- [ ] Azure updates blog

### Practice
- [ ] Microsoft Practice Assessment
- [ ] Whizlabs practice tests
- [ ] MeasureUp practice exams
- [ ] Udemy practice tests

### Community
- [ ] Azure subreddit
- [ ] Microsoft Tech Community
- [ ] Azure Friday videos
- [ ] John Savill's YouTube channel

---

## Post-Exam

**If you pass:**
- Update LinkedIn
- Share your experience
- Help others prepare

**If you don't pass:**
- Review exam feedback
- Identify weak areas
- Study those topics deeply
- Reschedule after 2 weeks

---

**Remember:** The exam tests your ability to design solutions, not memorize facts. Focus on understanding WHY you'd choose one service over another.

**© Copyright Sivakumar J**
