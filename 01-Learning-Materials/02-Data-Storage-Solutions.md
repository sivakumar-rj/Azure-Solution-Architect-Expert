# Domain 2: Design Data Storage Solutions (25-30%)

## 2.1 Design Data Storage Solutions for Relational Data

### Azure SQL Database

**Service Tiers:**
- **General Purpose:** Balanced compute and storage
- **Business Critical:** Low latency, high IOPS
- **Hyperscale:** Up to 100TB, rapid scale

**High Availability:**
- General Purpose: 99.99% SLA
- Business Critical: Always On availability groups
- Hyperscale: Multiple replicas

### Active Geo-Replication
- Up to 4 readable secondaries
- Any Azure region
- Asynchronous replication

## 2.2 Design Data Storage Solutions for Non-Relational Data

### Azure Storage Account

**Blob Access Tiers:**
- **Hot:** Frequent access
- **Cool:** Infrequent access (30+ days)
- **Archive:** Rare access (180+ days)

### Azure Cosmos DB

**Consistency Levels:**
1. Strong
2. Bounded Staleness
3. Session (default)
4. Consistent Prefix
5. Eventual

**Global Distribution:**
- Multi-region writes
- 99.999% availability SLA
- Single-digit millisecond latency

## 2.3 Design Data Integration Solutions

### Azure Data Factory
- Pipelines, Activities, Datasets, Linked Services, Triggers

### Azure Synapse Analytics
- Dedicated SQL Pool, Serverless SQL Pool, Spark Pools, Pipelines

### Azure Event Hubs
- Big data streaming platform
- Millions of events per second
- Kafka protocol support

## Storage Decision Tree

```
Need relational data?
├─ Yes → Azure SQL Database / SQL Managed Instance
└─ No
   ├─ Global distribution? → Cosmos DB
   ├─ File shares? → Azure Files
   ├─ Analytics? → Data Lake Storage Gen2
   └─ Object storage? → Blob Storage
```

## Key Takeaways

✅ Choose SQL Database for cloud-native apps  
✅ Use Cosmos DB for globally distributed apps  
✅ Select appropriate storage tier based on access patterns  
✅ Use Data Factory for ETL/ELT workflows

---

**© Copyright Sivakumar J**
