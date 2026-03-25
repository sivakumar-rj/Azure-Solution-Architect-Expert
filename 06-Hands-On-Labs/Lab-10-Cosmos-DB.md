# Lab 10: Cosmos DB

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI or Cosmos DB SDK
- Basic NoSQL knowledge

## Objective
Deploy and configure Azure Cosmos DB with multiple APIs and global distribution.

---

## Method 1: Azure Portal

### Create Cosmos DB Account
1. Navigate to Azure Portal
2. Search "Azure Cosmos DB" → Click "Create"
3. Select API: **Core (SQL)**
4. **Basics tab:**
   - Resource group: Create new → `rg-cosmos-lab`
   - Account name: `cosmos-lab-unique`
   - Location: `East US`
   - Capacity mode: `Provisioned throughput`
   - Apply Free Tier Discount: `Yes` (if available)
5. **Global Distribution tab:**
   - Geo-Redundancy: `Disable`
   - Multi-region Writes: `Disable`
6. Click "Review + Create" → "Create"

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-cosmos-lab-cli --location eastus

# Create Cosmos DB account (SQL API)
az cosmosdb create \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --locations regionName=eastus failoverPriority=0 \
  --default-consistency-level Session \
  --enable-free-tier true

# Create database
az cosmosdb sql database create \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --name productsdb \
  --throughput 400

# Create container
az cosmosdb sql container create \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --database-name productsdb \
  --name products \
  --partition-key-path "/category" \
  --throughput 400

# Get connection string
az cosmosdb keys list \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --type connection-strings
```

---

## Working with Data (SQL API)

### Using Azure Portal Data Explorer
1. Go to Cosmos DB account → "Data Explorer"
2. Create new item:
```json
{
  "id": "1",
  "category": "electronics",
  "name": "Laptop",
  "price": 999.99,
  "stock": 50
}
```

### Using Azure CLI
```bash
# Insert document
az cosmosdb sql container create-update \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --database-name productsdb \
  --name products \
  --partition-key-path "/category"
```

### Using Python SDK
```python
from azure.cosmos import CosmosClient, PartitionKey

# Initialize client
endpoint = "https://cosmos-lab-unique.documents.azure.com:443/"
key = "<PRIMARY_KEY>"
client = CosmosClient(endpoint, key)

# Get database and container
database = client.get_database_client("productsdb")
container = database.get_container_client("products")

# Create item
item = {
    "id": "1",
    "category": "electronics",
    "name": "Laptop",
    "price": 999.99,
    "stock": 50
}
container.create_item(body=item)

# Query items
query = "SELECT * FROM c WHERE c.category = 'electronics'"
items = list(container.query_items(query=query, enable_cross_partition_query=True))

# Update item
item['price'] = 899.99
container.replace_item(item=item['id'], body=item)

# Delete item
container.delete_item(item='1', partition_key='electronics')
```

---

## Configure Global Distribution

```bash
# Add region
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --locations regionName=eastus failoverPriority=0 \
  --locations regionName=westus failoverPriority=1

# Enable multi-region writes
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --enable-multiple-write-locations true

# Configure failover priority
az cosmosdb failover-priority-change \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --failover-policies eastus=0 westus=1
```

---

## Configure Consistency Levels

```bash
# Set consistency level
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --default-consistency-level Strong

# Available levels: Strong, BoundedStaleness, Session, ConsistentPrefix, Eventual
```

---

## Configure Throughput

```bash
# Update database throughput
az cosmosdb sql database throughput update \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --name productsdb \
  --throughput 1000

# Update container throughput
az cosmosdb sql container throughput update \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --database-name productsdb \
  --name products \
  --throughput 800

# Enable autoscale
az cosmosdb sql container throughput update \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --database-name productsdb \
  --name products \
  --max-throughput 4000
```

---

## Create MongoDB API Account

```bash
# Create Cosmos DB with MongoDB API
az cosmosdb create \
  --name cosmos-mongo-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --kind MongoDB \
  --server-version 4.2 \
  --locations regionName=eastus

# Get MongoDB connection string
az cosmosdb keys list \
  --name cosmos-mongo-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --type connection-strings \
  --query "connectionStrings[?description=='Primary MongoDB Connection String'].connectionString" -o tsv
```

### Connect with MongoDB Client
```bash
mongo "mongodb://cosmos-mongo-$RANDOM.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000" \
  --username cosmos-mongo-$RANDOM \
  --password <PRIMARY_KEY>
```

---

## Configure Backup and Restore

```bash
# Configure continuous backup
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --backup-policy-type Continuous

# Restore account
az cosmosdb restore \
  --target-database-account-name cosmos-restored \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --location eastus \
  --restore-timestamp "2026-03-25T10:00:00Z"
```

---

## Configure Security

```bash
# Enable firewall
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --ip-range-filter "40.76.54.131,52.176.6.30,<YOUR_IP>"

# Enable virtual network
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --enable-virtual-network true \
  --virtual-network-rules "/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Network/virtualNetworks/<VNET>/subnets/<SUBNET>"

# Disable public network access
az cosmosdb update \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli \
  --public-network-access Disabled
```

---

## Indexing Policies

```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/*"
    }
  ],
  "excludedPaths": [
    {
      "path": "/description/*"
    },
    {
      "path": "/_etag/?"
    }
  ],
  "compositeIndexes": [
    [
      {
        "path": "/category",
        "order": "ascending"
      },
      {
        "path": "/price",
        "order": "descending"
      }
    ]
  ]
}
```

---

## Stored Procedures

```javascript
function createDocument(item) {
    var context = getContext();
    var collection = context.getCollection();
    var response = context.getResponse();
    
    var accepted = collection.createDocument(
        collection.getSelfLink(),
        item,
        function(err, documentCreated) {
            if (err) throw new Error('Error: ' + err.message);
            response.setBody(documentCreated);
        }
    );
    
    if (!accepted) return;
}
```

---

## Verification Steps

```bash
# Check account status
az cosmosdb show \
  --name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli

# List databases
az cosmosdb sql database list \
  --account-name cosmos-lab-cli-$RANDOM \
  --resource-group rg-cosmos-lab-cli

# Monitor metrics
az monitor metrics list \
  --resource <COSMOS_RESOURCE_ID> \
  --metric TotalRequests \
  --output table
```

---

## Troubleshooting

**Issue: High RU consumption**
- Review indexing policy
- Optimize queries
- Use appropriate partition key
- Enable autoscale

**Issue: Throttling (429 errors)**
- Increase provisioned throughput
- Implement retry logic
- Optimize partition key distribution

**Issue: High latency**
- Use nearest region
- Enable multi-region writes
- Adjust consistency level

---

## Cleanup

```bash
az group delete --name rg-cosmos-lab-cli --yes --no-wait
```

---

## Key Takeaways
- Cosmos DB is globally distributed NoSQL database
- Multiple APIs: SQL, MongoDB, Cassandra, Gremlin, Table
- Five consistency levels for flexibility
- Automatic indexing by default
- Throughput measured in Request Units (RUs)
- Global distribution with multi-region writes
- 99.999% availability SLA with multi-region
