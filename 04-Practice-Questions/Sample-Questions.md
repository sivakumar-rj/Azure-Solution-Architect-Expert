# AZ-305 Practice Questions

## Domain 1: Identity, Governance, and Monitoring

**Question 1:**
Your company requires that all users accessing Azure resources from outside the corporate network must use MFA. Users on the corporate network should not be prompted for MFA. What should you implement?

A) Azure AD Identity Protection  
B) Conditional Access policy  
C) Azure AD Privileged Identity Management  
D) Azure AD Password Protection

**Answer:** B - Conditional Access policy allows you to create location-based policies.

---

**Question 2:**
You need to ensure that all Azure resources in your subscription have a "CostCenter" tag. Resources without this tag should not be created. What should you use?

A) Azure Blueprints  
B) Azure Policy with Deny effect  
C) Azure RBAC  
D) Management Groups

**Answer:** B - Azure Policy with Deny effect prevents resource creation if conditions aren't met.

---

## Domain 2: Data Storage Solutions

**Question 3:**
You need to design a globally distributed database solution with single-digit millisecond latency and 99.999% availability. Which service should you recommend?

A) Azure SQL Database with geo-replication  
B) Azure Cosmos DB with multi-region writes  
C) Azure Database for PostgreSQL  
D) Azure SQL Managed Instance

**Answer:** B - Cosmos DB provides global distribution and 99.999% SLA with multi-region configuration.

---

**Question 4:**
Your application stores 500 TB of data that is accessed once per year for compliance. What storage tier should you use?

A) Hot  
B) Cool  
C) Archive  
D) Premium

**Answer:** C - Archive tier is designed for rarely accessed data (180+ days).

---

## Domain 3: Business Continuity

**Question 5:**
You need to design a solution with RTO of 1 hour and RPO of 15 minutes for Azure VMs. What should you implement?

A) Azure Backup only  
B) Azure Site Recovery  
C) Availability Sets  
D) Availability Zones

**Answer:** B - Azure Site Recovery provides disaster recovery with configurable RTO/RPO.

---

**Question 6:**
Your web application must remain available even if an entire Azure datacenter fails. What should you implement?

A) Availability Set  
B) Availability Zones  
C) Load Balancer  
D) Azure Site Recovery

**Answer:** B - Availability Zones protect against datacenter-level failures.

---

## Domain 4: Infrastructure Solutions

**Question 7:**
You need to host a containerized application that requires VNet integration and auto-scaling. Which service should you use?

A) Azure Container Instances  
B) Azure Kubernetes Service  
C) Azure App Service  
D) Azure Functions

**Answer:** B - AKS provides VNet integration and auto-scaling for containers.

---

**Question 8:**
Your company needs a private connection to Azure with predictable network performance. Which service should you recommend?

A) Site-to-Site VPN  
B) Point-to-Site VPN  
C) ExpressRoute  
D) Azure Bastion

**Answer:** C - ExpressRoute provides private, predictable connectivity.

---

## Case Study Question

**Scenario:**
Contoso Ltd. is migrating their e-commerce application to Azure. Requirements:
- Global presence (US, Europe, Asia)
- 99.99% availability
- Sub-100ms response time for users
- SQL Server database with minimal changes
- Automatic failover

**Question 9:**
Which database solution should you recommend?

A) Azure SQL Database with active geo-replication  
B) SQL Server on Azure VMs with Always On  
C) Azure SQL Managed Instance with auto-failover groups  
D) Azure Cosmos DB

**Answer:** C - SQL Managed Instance provides SQL Server compatibility with auto-failover groups for high availability.

---

**Question 10:**
Which service should you use to distribute traffic globally?

A) Azure Load Balancer  
B) Azure Application Gateway  
C) Azure Front Door  
D) Azure Traffic Manager

**Answer:** C - Azure Front Door provides global load balancing with low latency.

---

## Tips for Practice

✅ Time yourself - 2 minutes per question  
✅ Read all options before answering  
✅ Look for keywords in questions  
✅ Eliminate wrong answers first  
✅ Review explanations for wrong answers  
✅ Practice case study scenarios
