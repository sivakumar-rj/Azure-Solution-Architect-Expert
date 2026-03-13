# Architecture Diagrams

This folder contains reference architectures and diagrams for common Azure patterns.

## Common Architecture Patterns

### 1. N-Tier Web Application
```
Internet
    ↓
Azure Front Door / Application Gateway
    ↓
Web Tier (App Service / VMs)
    ↓
Application Tier (App Service / AKS)
    ↓
Data Tier (Azure SQL / Cosmos DB)
```

### 2. Microservices Architecture
```
API Management
    ↓
├─ Service 1 (AKS Pod)
├─ Service 2 (AKS Pod)
└─ Service 3 (AKS Pod)
    ↓
Service Bus / Event Grid
    ↓
Azure SQL / Cosmos DB / Storage
```

### 3. Hub-Spoke Network Topology
```
        Hub VNet
    (Shared Services)
    /      |      \
   /       |       \
Spoke1  Spoke2  Spoke3
(Prod)  (Dev)   (Test)
```

### 4. Disaster Recovery Setup
```
Primary Region          Secondary Region
    VMs      ←→ ASR →      VMs (Stopped)
    SQL DB   ←→ Geo-Rep →  SQL DB (Read)
    Storage  ←→ GRS →      Storage
```

### 5. Data Analytics Pipeline
```
Data Sources
    ↓
Event Hubs / IoT Hub
    ↓
Stream Analytics
    ↓
Data Lake Storage Gen2
    ↓
Azure Synapse Analytics
    ↓
Power BI
```

## Diagram Tools

- **Microsoft Visio:** Official Azure stencils
- **Draw.io:** Free, Azure icon library
- **Lucidchart:** Cloud-based diagramming
- **Azure Architecture Icons:** https://learn.microsoft.com/azure/architecture/icons/

## Best Practices

✅ Use official Azure icons  
✅ Show data flow direction  
✅ Include security boundaries  
✅ Label all components  
✅ Show redundancy and failover paths  
✅ Include network segments  
✅ Document IP ranges and SKUs

---

**© Copyright Sivakumar J**
