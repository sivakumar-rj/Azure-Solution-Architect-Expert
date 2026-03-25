# Lab 09: MySQL Database

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- MySQL client or Azure CLI
- Basic MySQL knowledge

## Objective
Deploy and configure Azure Database for MySQL with security and high availability.

---

## Method 1: Azure Portal

### Create MySQL Server
1. Navigate to Azure Portal
2. Search "Azure Database for MySQL flexible servers" → Click "Create"
3. **Basics tab:**
   - Resource group: Create new → `rg-mysql-lab`
   - Server name: `mysql-lab-unique`
   - Region: `East US`
   - MySQL version: `8.0`
   - Compute + storage: `Burstable, B1ms`
   - Admin username: `mysqladmin`
   - Password: `P@ssw0rd123!`
4. **Networking tab:**
   - Connectivity: `Public access`
   - Add current client IP
   - Allow Azure services: `Yes`
5. Click "Review + Create" → "Create"

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-mysql-lab-cli --location eastus

# Create MySQL server
az mysql flexible-server create \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --location eastus \
  --admin-user mysqladmin \
  --admin-password 'P@ssw0rd123!' \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 8.0 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Create database
az mysql flexible-server db create \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --database-name appdb

# Configure firewall
az mysql flexible-server firewall-rule create \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --rule-name AllowMyIP \
  --start-ip-address <YOUR_IP> \
  --end-ip-address <YOUR_IP>

# Get connection string
az mysql flexible-server show-connection-string \
  --server-name mysql-lab-cli-$RANDOM \
  --database-name appdb \
  --admin-user mysqladmin \
  --admin-password 'P@ssw0rd123!'
```

---

## Connect to MySQL

```bash
# Using mysql client
mysql -h mysql-lab-cli-$RANDOM.mysql.database.azure.com \
  -u mysqladmin \
  -p'P@ssw0rd123!' \
  appdb

# Using Azure CLI
az mysql flexible-server connect \
  --name mysql-lab-cli-$RANDOM \
  --admin-user mysqladmin \
  --admin-password 'P@ssw0rd123!' \
  --database-name appdb
```

---

## Create Tables and Data

```sql
-- Create table
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert data
INSERT INTO products (name, price, stock) VALUES
    ('Laptop', 999.99, 50),
    ('Mouse', 29.99, 200),
    ('Keyboard', 79.99, 150);

-- Query data
SELECT * FROM products;

-- Create index
CREATE INDEX idx_name ON products(name);

-- Create stored procedure
DELIMITER //
CREATE PROCEDURE GetProductsByPrice(IN max_price DECIMAL(10,2))
BEGIN
    SELECT * FROM products WHERE price <= max_price;
END //
DELIMITER ;

-- Call procedure
CALL GetProductsByPrice(100.00);
```

---

## Configure High Availability

```bash
# Enable zone-redundant HA
az mysql flexible-server update \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --high-availability ZoneRedundant \
  --standby-zone 2

# Disable HA
az mysql flexible-server update \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --high-availability Disabled
```

---

## Configure Backup and Restore

```bash
# Configure backup retention
az mysql flexible-server update \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --backup-retention 14

# List backups
az mysql flexible-server backup list \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM

# Restore to point in time
az mysql flexible-server restore \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-restored \
  --source-server mysql-lab-cli-$RANDOM \
  --restore-time "2026-03-25T10:00:00Z"

# Geo-restore
az mysql flexible-server geo-restore \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-geo-restored \
  --source-server <SOURCE_SERVER_ID> \
  --location westus
```

---

## Configure Security

### SSL/TLS Configuration
```bash
# Require SSL
az mysql flexible-server parameter set \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --name require_secure_transport \
  --value ON

# Set minimum TLS version
az mysql flexible-server parameter set \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --name tls_version \
  --value "TLSv1.2,TLSv1.3"
```

### Private Endpoint
```bash
# Create VNet
az network vnet create \
  --resource-group rg-mysql-lab-cli \
  --name vnet-mysql \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-mysql \
  --subnet-prefix 10.0.1.0/24

# Create MySQL with private access
az mysql flexible-server create \
  --resource-group rg-mysql-lab-cli \
  --name mysql-private \
  --vnet vnet-mysql \
  --subnet subnet-mysql \
  --private-dns-zone mysql.private.database.azure.com \
  --admin-user mysqladmin \
  --admin-password 'P@ssw0rd123!'
```

---

## Configure Performance

### Scale Server
```bash
# Scale up
az mysql flexible-server update \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --sku-name Standard_D2ds_v4 \
  --tier GeneralPurpose

# Scale storage
az mysql flexible-server update \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM \
  --storage-size 128
```

### Configure Server Parameters
```bash
# Increase max connections
az mysql flexible-server parameter set \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --name max_connections \
  --value 500

# Configure query cache
az mysql flexible-server parameter set \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --name query_cache_size \
  --value 67108864

# List all parameters
az mysql flexible-server parameter list \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --output table
```

---

## Configure Read Replicas

```bash
# Create read replica
az mysql flexible-server replica create \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-replica \
  --source-server mysql-lab-cli-$RANDOM \
  --location eastus

# List replicas
az mysql flexible-server replica list \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM

# Stop replication (promote replica)
az mysql flexible-server replica stop-replication \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-replica
```

---

## Monitor Performance

```bash
# Enable slow query log
az mysql flexible-server parameter set \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --name slow_query_log \
  --value ON

az mysql flexible-server parameter set \
  --resource-group rg-mysql-lab-cli \
  --server-name mysql-lab-cli-$RANDOM \
  --name long_query_time \
  --value 2

# View metrics
az monitor metrics list \
  --resource <SERVER_RESOURCE_ID> \
  --metric cpu_percent \
  --output table
```

---

## Verification Steps

```bash
# Check server status
az mysql flexible-server show \
  --resource-group rg-mysql-lab-cli \
  --name mysql-lab-cli-$RANDOM

# Test connection
mysql -h mysql-lab-cli-$RANDOM.mysql.database.azure.com \
  -u mysqladmin \
  -p'P@ssw0rd123!' \
  -e "SELECT VERSION();"
```

---

## Troubleshooting

**Issue: Cannot connect**
- Verify firewall rules
- Check SSL/TLS requirements
- Ensure correct credentials

**Issue: Slow queries**
- Enable slow query log
- Check server parameters
- Consider scaling up
- Add indexes to tables

**Issue: Connection limit reached**
- Increase max_connections parameter
- Check for connection leaks in application
- Use connection pooling

---

## Cleanup

```bash
az group delete --name rg-mysql-lab-cli --yes --no-wait
```

---

## Key Takeaways
- Azure Database for MySQL is fully managed
- Flexible server offers better control and features
- Built-in high availability with zone redundancy
- Automatic backups with point-in-time restore
- Read replicas for read-heavy workloads
- Private endpoint for secure connectivity
- Server parameters for performance tuning
