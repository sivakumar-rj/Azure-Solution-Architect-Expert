# Lab 08: Azure SQL

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI or SQL Server Management Studio (SSMS)
- Basic SQL knowledge

## Objective
Deploy and configure Azure SQL Database with security and performance features.

---

## Method 1: Azure Portal

### Step 1: Create SQL Server
1. Navigate to Azure Portal
2. Search "SQL servers" → Click "Create"
3. Fill in details:
   - Resource group: Create new → `rg-sql-lab`
   - Server name: `sqlserver-lab-unique`
   - Location: `East US`
   - Authentication: `Use SQL authentication`
   - Server admin login: `sqladmin`
   - Password: `P@ssw0rd123!`
4. Click "Next: Networking"
5. Allow Azure services: `Yes`
6. Add current client IP: `Yes`
7. Click "Review + Create" → "Create"

### Step 2: Create SQL Database
1. Search "SQL databases" → Click "Create"
2. Fill in details:
   - Resource group: `rg-sql-lab`
   - Database name: `appdb`
   - Server: Select `sqlserver-lab-unique`
   - Compute + storage: `Basic (5 DTUs)`
3. Click "Review + Create" → "Create"

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-sql-lab-cli --location eastus

# Create SQL Server
az sql server create \
  --name sqlserver-lab-cli-$RANDOM \
  --resource-group rg-sql-lab-cli \
  --location eastus \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd123!'

# Configure firewall rule
az sql server firewall-rule create \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name AllowMyIP \
  --start-ip-address <YOUR_IP> \
  --end-ip-address <YOUR_IP>

# Allow Azure services
az sql server firewall-rule create \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create SQL Database
az sql db create \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --service-objective Basic \
  --backup-storage-redundancy Local

# Get connection string
az sql db show-connection-string \
  --client ado.net \
  --name appdb \
  --server sqlserver-lab-cli-$RANDOM
```

---

## Connect to Database

### Using Azure CLI
```bash
# Query database
az sql db query \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd123!' \
  --query "SELECT @@VERSION"
```

### Using sqlcmd
```bash
sqlcmd -S sqlserver-lab-cli-$RANDOM.database.windows.net \
  -d appdb \
  -U sqladmin \
  -P 'P@ssw0rd123!' \
  -Q "SELECT @@VERSION"
```

---

## Create Tables and Data

```sql
-- Create table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Insert data
INSERT INTO Customers (FirstName, LastName, Email)
VALUES 
    ('John', 'Doe', 'john@example.com'),
    ('Jane', 'Smith', 'jane@example.com'),
    ('Bob', 'Johnson', 'bob@example.com');

-- Query data
SELECT * FROM Customers;

-- Create index
CREATE INDEX IX_Customers_Email ON Customers(Email);

-- Create stored procedure
CREATE PROCEDURE GetCustomerByEmail
    @Email NVARCHAR(100)
AS
BEGIN
    SELECT * FROM Customers WHERE Email = @Email;
END;
```

---

## Configure Backup and Restore

```bash
# List backups
az sql db list-backups \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --database appdb

# Restore to point in time
az sql db restore \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb-restored \
  --source-database appdb \
  --time "2026-03-25T10:00:00Z"

# Export database (BACPAC)
az sql db export \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd123!' \
  --storage-key-type StorageAccessKey \
  --storage-key <STORAGE_KEY> \
  --storage-uri https://<STORAGE_ACCOUNT>.blob.core.windows.net/backups/appdb.bacpac

# Import database
az sql db import \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb-imported \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd123!' \
  --storage-key-type StorageAccessKey \
  --storage-key <STORAGE_KEY> \
  --storage-uri https://<STORAGE_ACCOUNT>.blob.core.windows.net/backups/appdb.bacpac
```

---

## Configure Security

### Enable Transparent Data Encryption (TDE)
```bash
az sql db tde set \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --database appdb \
  --status Enabled
```

### Enable Advanced Threat Protection
```bash
az sql server threat-policy update \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --state Enabled \
  --email-addresses admin@example.com
```

### Configure Auditing
```bash
az sql server audit-policy update \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --state Enabled \
  --storage-account <STORAGE_ACCOUNT>
```

### Enable Azure AD Authentication
```bash
# Set Azure AD admin
az sql server ad-admin create \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --display-name "SQL Admin" \
  --object-id <AZURE_AD_USER_OBJECT_ID>
```

---

## Configure Performance

### Scale Database
```bash
# Scale up
az sql db update \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --service-objective S1

# Scale to serverless
az sql db update \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --edition GeneralPurpose \
  --compute-model Serverless \
  --family Gen5 \
  --capacity 2 \
  --auto-pause-delay 60
```

### Enable Query Performance Insights
```bash
az sql db query-performance-insight show \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --database appdb
```

### Configure Automatic Tuning
```bash
az sql db update \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --auto-tuning-mode Auto
```

---

## Configure Geo-Replication

```bash
# Create secondary database
az sql db replica create \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --partner-server sqlserver-lab-secondary \
  --partner-resource-group rg-sql-lab-cli \
  --partner-location westus

# Failover to secondary
az sql db replica set-primary \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-secondary \
  --name appdb

# Remove secondary
az sql db replica delete-link \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --partner-server sqlserver-lab-secondary
```

---

## Configure Elastic Pool

```bash
# Create elastic pool
az sql elastic-pool create \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name pool1 \
  --edition Standard \
  --capacity 100 \
  --db-max-capacity 20 \
  --db-min-capacity 10

# Move database to pool
az sql db update \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb \
  --elastic-pool pool1
```

---

## Verification Steps

```bash
# Check database status
az sql db show \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM \
  --name appdb

# Check firewall rules
az sql server firewall-rule list \
  --resource-group rg-sql-lab-cli \
  --server sqlserver-lab-cli-$RANDOM

# Monitor metrics
az monitor metrics list \
  --resource <DATABASE_RESOURCE_ID> \
  --metric cpu_percent \
  --output table
```

---

## Troubleshooting

**Issue: Cannot connect**
- Verify firewall rules include your IP
- Check server name and credentials
- Ensure Azure services access is allowed

**Issue: Performance issues**
- Check DTU/vCore usage
- Review Query Performance Insights
- Enable automatic tuning
- Consider scaling up

**Issue: High costs**
- Use serverless tier for intermittent workloads
- Enable auto-pause for dev/test databases
- Consider elastic pools for multiple databases

---

## Cleanup

```bash
az group delete --name rg-sql-lab-cli --yes --no-wait
```

---

## Key Takeaways
- Azure SQL Database is fully managed PaaS
- Automatic backups with point-in-time restore
- Built-in high availability (99.99% SLA)
- TDE encrypts data at rest by default
- Geo-replication for disaster recovery
- Serverless tier for cost optimization
- Elastic pools share resources across databases
