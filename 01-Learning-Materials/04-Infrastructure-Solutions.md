# Domain 4: Design Infrastructure Solutions (30-35%)

## 4.1 Design Compute Solutions

### Azure Virtual Machines

**VM Series:**
- **A-Series:** Entry-level, dev/test
- **B-Series:** Burstable, variable workloads
- **D-Series:** General purpose
- **E-Series:** Memory-optimized
- **F-Series:** Compute-optimized
- **N-Series:** GPU-enabled

### Azure App Service

**Plans:**
- **Free/Shared:** Shared infrastructure
- **Basic:** Dedicated, no auto-scale
- **Standard:** Auto-scale, staging slots
- **Premium:** Enhanced performance, VNet integration
- **Isolated:** Dedicated environment (App Service Environment)

### Azure Kubernetes Service (AKS)

**Features:**
- Managed Kubernetes
- Automatic upgrades
- Built-in monitoring
- Azure AD integration
- Virtual nodes (ACI integration)

### Azure Container Instances (ACI)
- Serverless containers
- Per-second billing
- Fast startup

### Azure Functions

**Hosting Plans:**
- **Consumption:** Pay per execution, auto-scale
- **Premium:** Pre-warmed instances, VNet integration
- **Dedicated:** App Service plan

## 4.2 Design Network Solutions

### Virtual Network (VNet)

**Address Space:** RFC 1918 private addresses
- 10.0.0.0/8
- 172.16.0.0/12
- 192.168.0.0/16

### Network Security

**Network Security Groups (NSG):**
- Stateful firewall
- Allow/Deny rules
- Priority 100-4096

**Azure Firewall:**
- Managed firewall service
- Application and network rules
- Threat intelligence
- Forced tunneling

### Connectivity Options

**VPN Gateway:**
- Site-to-Site (S2S)
- Point-to-Site (P2S)
- VNet-to-VNet

**ExpressRoute:**
- Private connection to Azure
- 50 Mbps to 10 Gbps
- Predictable performance
- Higher cost

### Azure DNS
- Host DNS domains
- Private DNS zones
- Alias records

## 4.3 Design Application Architecture Solutions

### Microservices Patterns

**API Management:**
- API gateway
- Rate limiting
- Authentication
- Caching
- Monitoring

**Service Bus:**
- Enterprise messaging
- Queues and Topics
- Dead-letter queues
- Sessions

**Event Grid:**
- Event-driven architecture
- Publish-subscribe model
- Built-in Azure events

### Caching Strategies

**Azure Cache for Redis:**
- Cache-aside pattern
- Session store
- Message broker

## 4.4 Design Migrations

### Azure Migrate

**Tools:**
- Discovery and assessment
- Server migration
- Database migration
- Web app migration

### Database Migration Service (DMS)
- Minimal downtime migrations
- SQL Server to Azure SQL
- PostgreSQL, MySQL, MongoDB

### Migration Strategies

**5 R's:**
1. **Rehost:** Lift-and-shift
2. **Refactor:** Minor modifications
3. **Rearchitect:** Significant changes
4. **Rebuild:** Redesign from scratch
5. **Replace:** SaaS alternatives

## Key Takeaways

✅ Choose appropriate compute service for workload  
✅ Design network with proper segmentation  
✅ Implement defense-in-depth security  
✅ Use managed services when possible  
✅ Plan migrations with proper assessment

---

**© Copyright Sivakumar J - All Rights Reserved**
