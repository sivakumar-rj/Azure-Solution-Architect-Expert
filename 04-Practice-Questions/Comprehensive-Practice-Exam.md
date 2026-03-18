# AZ-305 Practice Questions - Comprehensive Set

## Section 1: Identity & Governance (30 Questions)

### Identity Management

**Q1:** A company requires that all privileged role assignments in Azure AD must be time-limited and require approval. Which solution should you implement?
- A) Azure AD Conditional Access
- B) Azure AD Privileged Identity Management (PIM)
- C) Azure AD Identity Protection
- D) Azure RBAC custom roles

**Answer: B**  
**Explanation:** PIM provides just-in-time privileged access with approval workflows and time-limited assignments.

---

**Q2:** You need to allow external partners to access specific Azure resources without creating guest accounts. What should you use?
- A) Azure AD B2B
- B) Azure AD B2C
- C) Service principals
- D) Managed identities

**Answer: A**  
**Explanation:** Azure AD B2B allows external users to access resources using their own credentials.

---

**Q3:** An application running in AKS needs to access Azure Key Vault without storing credentials. What should you implement?
- A) Service principal with certificate
- B) User-assigned managed identity
- C) System-assigned managed identity
- D) Shared access signature

**Answer: B**  
**Explanation:** User-assigned managed identity can be shared across multiple resources and doesn't require credential management.

---

### Governance

**Q4:** You need to enforce that all storage accounts must use HTTPS only. Non-compliant resources should be automatically remediated. Which Azure Policy effect should you use?
- A) Deny
- B) Audit
- C) DeployIfNotExists
- D) Modify

**Answer: D**  
**Explanation:** Modify effect can automatically remediate non-compliant resources by updating properties.

---

**Q5:** Your organization has 50 subscriptions. You need to apply consistent policies across all subscriptions. What should you use?
- A) Azure Policy at subscription level
- B) Management groups with Azure Policy
- C) Azure Blueprints
- D) Resource groups

**Answer: B**  
**Explanation:** Management groups allow you to apply policies across multiple subscriptions hierarchically.

---

**Q6:** You need to deploy a complete environment (VNet, VMs, policies, RBAC) as a repeatable template. What should you use?
- A) ARM templates
- B) Azure Policy
- C) Azure Blueprints
- D) Terraform

**Answer: C**  
**Explanation:** Azure Blueprints package ARM templates, policies, and RBAC assignments as a single deployable unit.

---

### Monitoring

**Q7:** You need to collect custom application metrics and correlate them with infrastructure metrics. Which service should you use?
- A) Azure Monitor Metrics
- B) Application Insights
- C) Log Analytics
- D) Azure Advisor

**Answer: B**  
**Explanation:** Application Insights provides APM capabilities with custom metrics and correlation with infrastructure.

---

**Q8:** You need to query logs from multiple Azure resources using KQL. What should you use?
- A) Azure Monitor Metrics
- B) Application Insights
- C) Log Analytics workspace
- D) Azure Activity Log

**Answer: C**  
**Explanation:** Log Analytics workspace allows querying logs from multiple sources using KQL.

---

**Q9:** You need to receive alerts when VM CPU exceeds 80% for 5 minutes. What should you configure?
- A) Azure Monitor metric alert
- B) Azure Monitor log alert
- C) Azure Advisor recommendation
- D) Azure Service Health alert

**Answer: A**  
**Explanation:** Metric alerts are designed for threshold-based monitoring of metrics like CPU.

---

**Q10:** You need to analyze network traffic between Azure VMs to troubleshoot connectivity issues. Which tool should you use?
- A) Azure Monitor
- B) Network Watcher NSG Flow Logs
- C) Azure Advisor
- D) Application Insights

**Answer: B**  
**Explanation:** NSG Flow Logs capture network traffic information for troubleshooting.

---

## Section 2: Data Storage (30 Questions)

### Storage Accounts

**Q11:** You need to store 10 PB of data that will be accessed frequently for the first 30 days, then rarely. What should you implement?
- A) Hot tier with manual tier change
- B) Cool tier
- C) Archive tier
- D) Lifecycle management policy

**Answer: D**  
**Explanation:** Lifecycle management automatically transitions blobs between tiers based on rules.

---

**Q12:** Your application requires 99.99% availability for read operations and can tolerate eventual consistency. Which redundancy option provides the most cost-effective solution?
- A) LRS
- B) ZRS
- C) GRS
- D) RA-GRS

**Answer: D**  
**Explanation:** RA-GRS provides read access to secondary region for high availability at lower cost than GZRS.

---

**Q13:** You need to provide temporary access to a blob for external users without sharing account keys. What should you use?
- A) Shared access signature (SAS)
- B) Stored access policy
- C) Azure AD authentication
- D) Anonymous access

**Answer: A**  
**Explanation:** SAS tokens provide time-limited, granular access without exposing account keys.

---

**Q14:** You need to mount Azure file shares on both Windows and Linux VMs. Which protocol should you use?
- A) SMB only
- B) NFS only
- C) SMB for Windows, NFS for Linux
- D) REST API

**Answer: C**  
**Explanation:** Azure Files supports SMB for Windows and NFS for Linux.

---

### Databases

**Q15:** You need to migrate a SQL Server database with minimal downtime and no code changes. Which service should you use?
- A) Azure SQL Database
- B) Azure SQL Managed Instance
- C) SQL Server on Azure VM
- D) Azure Cosmos DB

**Answer: B**  
**Explanation:** SQL Managed Instance provides near 100% compatibility with SQL Server for lift-and-shift scenarios.

---

**Q16:** Your application requires single-digit millisecond latency globally with automatic failover. Which Cosmos DB consistency level provides the best balance?
- A) Strong
- B) Bounded Staleness
- C) Session
- D) Eventual

**Answer: C**  
**Explanation:** Session consistency provides read-your-writes guarantee with low latency, suitable for most applications.

---

**Q17:** You need to scale an Azure SQL Database to handle unpredictable workloads cost-effectively. What should you use?
- A) DTU-based pricing
- B) vCore-based pricing
- C) Elastic pool
- D) Serverless compute tier

**Answer: D**  
**Explanation:** Serverless automatically scales and pauses during inactivity, ideal for unpredictable workloads.

---

**Q18:** Your application needs to cache session data with sub-millisecond latency. Which service should you use?
- A) Azure SQL Database
- B) Azure Cosmos DB
- C) Azure Cache for Redis
- D) Azure Table Storage

**Answer: C**  
**Explanation:** Redis provides in-memory caching with sub-millisecond latency.

---

**Q19:** You need to partition a Cosmos DB container for optimal performance. Which property should you choose as partition key?
- A) Property with high cardinality and even distribution
- B) Property with low cardinality
- C) Timestamp field
- D) Auto-generated GUID

**Answer: A**  
**Explanation:** High cardinality with even distribution prevents hot partitions and ensures scalability.

---

**Q20:** You need to analyze 500 TB of data using SQL queries. Which service should you use?
- A) Azure SQL Database
- B) Azure Synapse Analytics
- C) Azure Databricks
- D) Azure Data Lake Storage

**Answer: B**  
**Explanation:** Azure Synapse Analytics is designed for large-scale data warehousing and analytics.

---

### Data Integration

**Q21:** You need to ingest real-time streaming data from IoT devices and process it. Which combination should you use?
- A) Event Hubs + Stream Analytics
- B) Service Bus + Logic Apps
- C) Event Grid + Functions
- D) Storage Queue + WebJobs

**Answer: A**  
**Explanation:** Event Hubs ingests high-volume streaming data, Stream Analytics processes it in real-time.

---

**Q22:** You need to trigger an Azure Function when a blob is uploaded to storage. Which service should you use?
- A) Event Hubs
- B) Event Grid
- C) Service Bus
- D) Storage Queue

**Answer: B**  
**Explanation:** Event Grid provides event-driven architecture with blob storage events.

---

**Q23:** You need to orchestrate complex data workflows with dependencies and error handling. What should you use?
- A) Azure Logic Apps
- B) Azure Functions
- C) Azure Data Factory
- D) Azure Automation

**Answer: C**  
**Explanation:** Data Factory provides visual workflow orchestration for ETL/ELT pipelines.

---

## Section 3: Business Continuity (25 Questions)

### Backup & DR

**Q24:** You need to backup Azure VMs with 4-hour RPO and 8-hour RTO. What should you configure?
- A) Azure Backup with daily backup
- B) Azure Backup with 4-hour backup frequency
- C) Azure Site Recovery
- D) Snapshot every 4 hours

**Answer: B**  
**Explanation:** Backup frequency must match RPO requirement (4 hours).

---

**Q25:** Your on-premises VMs need disaster recovery to Azure with 15-minute RPO. What should you implement?
- A) Azure Backup
- B) Azure Site Recovery
- C) Azure Migrate
- D) Manual snapshots

**Answer: B**  
**Explanation:** ASR provides continuous replication with RPO as low as 30 seconds.

---

**Q26:** You need to restore a deleted blob within 14 days. What should you enable?
- A) Versioning
- B) Soft delete
- C) Immutable storage
- D) Lifecycle management

**Answer: B**  
**Explanation:** Soft delete retains deleted blobs for specified retention period.

---

**Q27:** You need to protect Azure SQL Database from accidental deletion or modification. What should you implement?
- A) Resource lock
- B) Azure Backup
- C) Point-in-time restore
- D) Geo-replication

**Answer: A**  
**Explanation:** Resource locks prevent accidental deletion or modification of resources.

---

### High Availability

**Q28:** You need to achieve 99.99% SLA for VMs. What should you implement?
- A) Single VM with Premium SSD
- B) Availability Set with 2 VMs
- C) Availability Zones with 2 VMs
- D) VM Scale Set

**Answer: C**  
**Explanation:** Availability Zones provide 99.99% SLA by distributing VMs across physical datacenters.

---

**Q29:** Your web application must remain available during Azure datacenter maintenance. What should you use?
- A) Availability Set
- B) Availability Zones
- C) Load Balancer
- D) Application Gateway

**Answer: B**  
**Explanation:** Availability Zones protect against datacenter-level failures including maintenance.

---

**Q30:** You need to distribute traffic across VMs in different regions. Which service should you use?
- A) Azure Load Balancer
- B) Application Gateway
- C) Traffic Manager
- D) Azure Front Door

**Answer: C or D**  
**Explanation:** Both Traffic Manager (DNS-based) and Front Door (anycast) provide global load balancing. Front Door offers additional features like WAF and caching.

---

**Q31:** You need to calculate the composite SLA for an application using App Service (99.95%) and SQL Database (99.99%). What is the composite SLA?
- A) 99.94%
- B) 99.95%
- C) 99.99%
- D) 99.89%

**Answer: A**  
**Explanation:** Composite SLA = 0.9995 × 0.9999 = 0.9994 = 99.94%

---

## Section 4: Infrastructure Solutions (35 Questions)

### Compute

**Q32:** You need to run a batch processing job that can tolerate interruptions and requires GPU. What should you use?
- A) Standard VMs
- B) Spot VMs
- C) Azure Batch
- D) Azure Functions

**Answer: B**  
**Explanation:** Spot VMs provide up to 90% cost savings for interruptible workloads.

---

**Q33:** Your web application has unpredictable traffic patterns. Which App Service plan should you use?
- A) Free
- B) Shared
- C) Basic
- D) Premium v3 with autoscale

**Answer: D**  
**Explanation:** Premium plans support autoscaling for handling variable traffic.

---

**Q34:** You need to deploy a containerized application without managing infrastructure. Which service should you use?
- A) Azure Kubernetes Service
- B) Azure Container Instances
- C) App Service for Containers
- D) Azure Functions

**Answer: C**  
**Explanation:** App Service for Containers provides PaaS experience for containerized apps without infrastructure management.

---

**Q35:** You need to run a microservices application with service mesh and advanced networking. What should you use?
- A) Azure Container Instances
- B) Azure Kubernetes Service
- C) App Service
- D) Azure Functions

**Answer: B**  
**Explanation:** AKS supports service mesh (Istio/Linkerd) and advanced networking features.

---

**Q36:** You need to process messages from a queue with automatic scaling to zero when idle. What should you use?
- A) Azure Functions (Consumption plan)
- B) Azure Functions (Premium plan)
- C) Azure Logic Apps
- D) Azure Batch

**Answer: A**  
**Explanation:** Consumption plan scales to zero automatically when idle, providing cost savings.

---

### Networking

**Q37:** You need to connect two VNets in different regions. What should you use?
- A) VPN Gateway
- B) ExpressRoute
- C) Global VNet peering
- D) Azure Firewall

**Answer: C**  
**Explanation:** Global VNet peering connects VNets across regions with low latency.

---

**Q38:** You need to provide secure RDP access to VMs without exposing them to the internet. What should you use?
- A) Public IP with NSG
- B) Azure Bastion
- C) VPN Gateway
- D) ExpressRoute

**Answer: B**  
**Explanation:** Azure Bastion provides secure RDP/SSH access without public IPs.

---

**Q39:** You need to filter traffic between subnets within a VNet. What should you use?
- A) Azure Firewall
- B) Network Security Groups (NSG)
- C) Application Security Groups (ASG)
- D) Route tables

**Answer: B**  
**Explanation:** NSGs filter traffic at subnet and NIC level within VNets.

---

**Q40:** You need to inspect and filter all outbound internet traffic from VMs. What should you implement?
- A) NSG
- B) Azure Firewall
- C) Application Gateway
- D) Load Balancer

**Answer: B**  
**Explanation:** Azure Firewall provides stateful firewall with FQDN filtering for outbound traffic.

---

**Q41:** You need to provide private connectivity to Azure SQL Database from on-premises. What should you use?
- A) Service Endpoint
- B) Private Link
- C) VNet peering
- D) ExpressRoute with public peering

**Answer: B**  
**Explanation:** Private Link provides private IP access to PaaS services over ExpressRoute/VPN.

---

**Q42:** You need to resolve custom domain names within a VNet. What should you use?
- A) Azure DNS public zone
- B) Azure DNS private zone
- C) Custom DNS server
- D) Azure Traffic Manager

**Answer: B**  
**Explanation:** Private DNS zones provide name resolution within VNets.

---

**Q43:** You need to protect a web application from SQL injection and XSS attacks. What should you use?
- A) NSG
- B) Azure Firewall
- C) Application Gateway with WAF
- D) Azure DDoS Protection

**Answer: C**  
**Explanation:** WAF on Application Gateway protects against OWASP top 10 vulnerabilities.

---

### Containers & Microservices

**Q44:** You need to automatically scale AKS pods based on CPU and custom metrics. What should you implement?
- A) Cluster Autoscaler only
- B) Horizontal Pod Autoscaler only
- C) Both HPA and Cluster Autoscaler
- D) Manual scaling

**Answer: C**  
**Explanation:** HPA scales pods, Cluster Autoscaler scales nodes to accommodate pods.

---

**Q45:** You need to store container images privately with geo-replication. What should you use?
- A) Docker Hub
- B) Azure Container Registry (Basic)
- C) Azure Container Registry (Premium)
- D) GitHub Container Registry

**Answer: C**  
**Explanation:** Premium ACR supports geo-replication for high availability.

---

**Q46:** You need to implement blue-green deployment for AKS workloads. What should you use?
- A) Deployment with rolling update
- B) Two deployments with service selector switch
- C) StatefulSet
- D) DaemonSet

**Answer: B**  
**Explanation:** Blue-green uses two deployments; switch traffic by updating service selector.

---

**Q47:** You need to provide AKS pods access to Azure Key Vault secrets. What should you implement?
- A) Kubernetes secrets
- B) Azure Key Vault CSI driver with workload identity
- C) Environment variables
- D) ConfigMaps

**Answer: B**  
**Explanation:** CSI driver with workload identity provides secure, managed access to Key Vault.

---

**Q48:** You need to implement network policies in AKS to control pod-to-pod traffic. Which network plugin should you use?
- A) Kubenet
- B) Azure CNI
- C) Flannel
- D) Host networking

**Answer: B**  
**Explanation:** Azure CNI supports network policies (Calico or Azure Network Policy).

---

## Section 5: Case Studies (10 Questions)

### Case Study 1: E-Commerce Platform

**Scenario:** Contoso operates a global e-commerce platform with the following requirements:
- 10 million users across US, Europe, and Asia
- 99.99% availability
- Sub-100ms response time globally
- PCI DSS compliance
- SQL Server database (2 TB)
- Peak traffic during holidays (10x normal)

**Q49:** Which database solution should you recommend?
- A) Azure SQL Database with active geo-replication
- B) SQL Managed Instance with failover groups
- C) SQL Server on Azure VMs
- D) Cosmos DB

**Answer: B**  
**Explanation:** SQL MI provides SQL Server compatibility with auto-failover groups for HA across regions.

---

**Q50:** Which global load balancing solution should you use?
- A) Azure Load Balancer
- B) Application Gateway
- C) Azure Front Door with WAF
- D) Traffic Manager

**Answer: C**  
**Explanation:** Front Door provides global load balancing, CDN, and WAF for security compliance.

---

**Q51:** How should you handle peak traffic during holidays?
- A) Overprovision resources year-round
- B) VM Scale Sets with autoscale
- C) Manual scaling before holidays
- D) Use larger VM sizes

**Answer: B**  
**Explanation:** VMSS with autoscale automatically handles traffic spikes cost-effectively.

---

### Case Study 2: Healthcare Application

**Scenario:** A healthcare provider needs to migrate their patient management system:
- HIPAA compliance required
- 24/7 availability
- Data must stay in specific regions
- Integration with on-premises systems
- Audit all data access

**Q52:** How should you ensure data residency compliance?
- A) Use any Azure region
- B) Deploy to specific regions with data residency
- C) Use Azure Policy to restrict regions
- D) Both B and C

**Answer: D**  
**Explanation:** Deploy to compliant regions and use Azure Policy to prevent deployment to non-compliant regions.

---

**Q53:** How should you audit all data access?
- A) Azure Monitor only
- B) Azure AD audit logs only
- C) Diagnostic settings + Log Analytics + Azure AD logs
- D) Application logging only

**Answer: C**  
**Explanation:** Comprehensive auditing requires diagnostic settings, Log Analytics, and Azure AD logs.

---

**Q54:** How should you connect to on-premises systems securely?
- A) Site-to-Site VPN
- B) ExpressRoute with private peering
- C) Point-to-Site VPN
- D) Public internet with TLS

**Answer: B**  
**Explanation:** ExpressRoute provides dedicated, secure connectivity for healthcare compliance.

---

### Case Study 3: IoT Solution

**Scenario:** Manufacturing company deploying IoT solution:
- 100,000 devices sending telemetry every second
- Real-time anomaly detection
- Historical data analysis
- Predictive maintenance
- Cost optimization

**Q55:** Which service should you use to ingest telemetry?
- A) Event Grid
- B) Event Hubs
- C) Service Bus
- D) Storage Queue

**Answer: B**  
**Explanation:** Event Hubs handles millions of events per second for IoT scenarios.

---

**Q56:** How should you implement real-time anomaly detection?
- A) Azure Functions
- B) Azure Stream Analytics
- C) Azure Databricks
- D) Azure Synapse Analytics

**Answer: B**  
**Explanation:** Stream Analytics provides real-time processing with built-in ML for anomaly detection.

---

**Q57:** Where should you store historical data for analysis?
- A) Azure SQL Database
- B) Cosmos DB
- C) Azure Data Lake Storage Gen2
- D) Blob Storage (Hot tier)

**Answer: C**  
**Explanation:** Data Lake Storage Gen2 is optimized for big data analytics with hierarchical namespace.

---

**Q58:** How should you optimize costs for infrequently accessed historical data?
- A) Keep in Data Lake Storage Gen2 (Hot)
- B) Use lifecycle management to move to Cool/Archive
- C) Delete old data
- D) Compress data manually

**Answer: B**  
**Explanation:** Lifecycle management automatically transitions data to lower-cost tiers.

---

## Answer Key Summary

**Section 1 (Identity & Governance):** B, A, B, D, B, C, B, C, A, B  
**Section 2 (Data Storage):** D, D, A, C, B, C, D, C, A, B, A, B, C  
**Section 3 (Business Continuity):** B, B, B, A, C, B, C/D, A  
**Section 4 (Infrastructure):** B, D, C, B, A, C, B, B, B, B, B, C, C, C, B, B, B  
**Section 5 (Case Studies):** B, C, B, D, C, B, B, B, C, B

---

**© Copyright Sivakumar J**
