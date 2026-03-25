# Lab 24: Three-Tier App

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Understanding of multi-tier architecture
- Basic web development knowledge

## Objective
Deploy a three-tier application with web, application, and database tiers.

---

## Architecture Overview

```
Internet → Application Gateway (WAF) → Web Tier (VMs/VMSS)
                                          ↓
                                    App Tier (VMs/App Service)
                                          ↓
                                    Database Tier (Azure SQL)
```

---

## Create Infrastructure

```bash
# Create resource group
az group create --name rg-threetier-lab --location eastus

# Create VNet with subnets
az network vnet create \
  --resource-group rg-threetier-lab \
  --name vnet-app \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-appgw \
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group rg-threetier-lab \
  --vnet-name vnet-app \
  --name subnet-web \
  --address-prefix 10.0.2.0/24

az network vnet subnet create \
  --resource-group rg-threetier-lab \
  --vnet-name vnet-app \
  --name subnet-app \
  --address-prefix 10.0.3.0/24

az network vnet subnet create \
  --resource-group rg-threetier-lab \
  --vnet-name vnet-app \
  --name subnet-db \
  --address-prefix 10.0.4.0/24
```

---

## Deploy Database Tier

```bash
# Create Azure SQL Server
az sql server create \
  --resource-group rg-threetier-lab \
  --name sqlserver-threetier-$RANDOM \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd123!' \
  --location eastus

# Create database
az sql db create \
  --resource-group rg-threetier-lab \
  --server sqlserver-threetier-$RANDOM \
  --name appdb \
  --service-objective S1

# Configure firewall for app subnet
az sql server vnet-rule create \
  --resource-group rg-threetier-lab \
  --server sqlserver-threetier-$RANDOM \
  --name allow-app-subnet \
  --vnet-name vnet-app \
  --subnet subnet-app

# Get connection string
CONNECTION_STRING=$(az sql db show-connection-string \
  --client ado.net \
  --name appdb \
  --server sqlserver-threetier-$RANDOM | \
  sed 's/<username>/sqladmin/g' | \
  sed 's/<password>/P@ssw0rd123!/g')
```

---

## Deploy Application Tier

```bash
# Create App Service Plan
az appservice plan create \
  --resource-group rg-threetier-lab \
  --name plan-app-tier \
  --sku S1 \
  --is-linux

# Create App Service (API)
az webapp create \
  --resource-group rg-threetier-lab \
  --plan plan-app-tier \
  --name api-threetier-$RANDOM \
  --runtime "NODE:20-lts"

# Configure VNet integration
az webapp vnet-integration add \
  --resource-group rg-threetier-lab \
  --name api-threetier-$RANDOM \
  --vnet vnet-app \
  --subnet subnet-app

# Configure app settings
az webapp config appsettings set \
  --resource-group rg-threetier-lab \
  --name api-threetier-$RANDOM \
  --settings \
    DB_CONNECTION_STRING="$CONNECTION_STRING" \
    NODE_ENV=production
```

**API Application (app.js):**
```javascript
const express = require('express');
const sql = require('mssql');
const app = express();

app.use(express.json());

const config = {
    connectionString: process.env.DB_CONNECTION_STRING
};

// Get all products
app.get('/api/products', async (req, res) => {
    try {
        await sql.connect(config);
        const result = await sql.query`SELECT * FROM Products`;
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({error: err.message});
    }
});

// Get product by ID
app.get('/api/products/:id', async (req, res) => {
    try {
        await sql.connect(config);
        const result = await sql.query`SELECT * FROM Products WHERE id = ${req.params.id}`;
        res.json(result.recordset[0]);
    } catch (err) {
        res.status(500).json({error: err.message});
    }
});

// Create product
app.post('/api/products', async (req, res) => {
    try {
        await sql.connect(config);
        const {name, price} = req.body;
        const result = await sql.query`INSERT INTO Products (name, price) VALUES (${name}, ${price})`;
        res.status(201).json({message: 'Product created'});
    } catch (err) {
        res.status(500).json({error: err.message});
    }
});

app.listen(process.env.PORT || 3000);
```

---

## Deploy Web Tier

```bash
# Create VMSS for web tier
az vmss create \
  --resource-group rg-threetier-lab \
  --name vmss-web \
  --image Ubuntu2204 \
  --vnet-name vnet-app \
  --subnet subnet-web \
  --vm-sku Standard_B2s \
  --instance-count 2 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --upgrade-policy-mode Automatic \
  --load-balancer "" \
  --public-ip-address ""

# Install web server
az vmss extension set \
  --resource-group rg-threetier-lab \
  --vmss-name vmss-web \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{"commandToExecute":"apt-get update && apt-get install -y nginx && systemctl enable nginx"}'
```

**Web Application (index.html):**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Three-Tier App</title>
</head>
<body>
    <h1>Product Catalog</h1>
    <div id="products"></div>
    
    <script>
        fetch('https://api-threetier.azurewebsites.net/api/products')
            .then(response => response.json())
            .then(data => {
                const container = document.getElementById('products');
                data.forEach(product => {
                    container.innerHTML += `
                        <div>
                            <h3>${product.name}</h3>
                            <p>Price: $${product.price}</p>
                        </div>
                    `;
                });
            });
    </script>
</body>
</html>
```

---

## Deploy Application Gateway

```bash
# Create public IP
az network public-ip create \
  --resource-group rg-threetier-lab \
  --name pip-appgw \
  --sku Standard \
  --allocation-method Static

# Create Application Gateway
az network application-gateway create \
  --resource-group rg-threetier-lab \
  --name appgw-web \
  --vnet-name vnet-app \
  --subnet subnet-appgw \
  --public-ip-address pip-appgw \
  --sku WAF_v2 \
  --capacity 2 \
  --http-settings-port 80 \
  --http-settings-protocol Http

# Add backend pool with VMSS
az network application-gateway address-pool create \
  --resource-group rg-threetier-lab \
  --gateway-name appgw-web \
  --name pool-web \
  --servers 10.0.2.4 10.0.2.5
```

---

## Configure NSGs

```bash
# Web tier NSG
az network nsg create \
  --resource-group rg-threetier-lab \
  --name nsg-web

az network nsg rule create \
  --resource-group rg-threetier-lab \
  --nsg-name nsg-web \
  --name Allow-AppGW \
  --priority 100 \
  --source-address-prefixes 10.0.1.0/24 \
  --destination-port-ranges 80 443 \
  --access Allow

# App tier NSG
az network nsg create \
  --resource-group rg-threetier-lab \
  --name nsg-app

az network nsg rule create \
  --resource-group rg-threetier-lab \
  --nsg-name nsg-app \
  --name Allow-Web \
  --priority 100 \
  --source-address-prefixes 10.0.2.0/24 \
  --destination-port-ranges 443 \
  --access Allow

# DB tier NSG
az network nsg create \
  --resource-group rg-threetier-lab \
  --name nsg-db

az network nsg rule create \
  --resource-group rg-threetier-lab \
  --nsg-name nsg-db \
  --name Allow-App \
  --priority 100 \
  --source-address-prefixes 10.0.3.0/24 \
  --destination-port-ranges 1433 \
  --access Allow

# Associate NSGs
az network vnet subnet update \
  --resource-group rg-threetier-lab \
  --vnet-name vnet-app \
  --name subnet-web \
  --network-security-group nsg-web

az network vnet subnet update \
  --resource-group rg-threetier-lab \
  --vnet-name vnet-app \
  --name subnet-app \
  --network-security-group nsg-app

az network vnet subnet update \
  --resource-group rg-threetier-lab \
  --vnet-name vnet-app \
  --name subnet-db \
  --network-security-group nsg-db
```

---

## Configure Monitoring

```bash
# Enable Application Insights
az monitor app-insights component create \
  --app threetier-insights \
  --location eastus \
  --resource-group rg-threetier-lab \
  --application-type web

# Connect to App Service
az monitor app-insights component connect-webapp \
  --resource-group rg-threetier-lab \
  --app threetier-insights \
  --web-app api-threetier-$RANDOM

# Enable diagnostics
az monitor diagnostic-settings create \
  --name appgw-diagnostics \
  --resource <APPGW_ID> \
  --workspace <WORKSPACE_ID> \
  --logs '[{"category": "ApplicationGatewayAccessLog", "enabled": true}]'
```

---

## Key Takeaways
- Three-tier architecture separates concerns
- Each tier in separate subnet with NSGs
- Application Gateway provides WAF and load balancing
- VNet integration secures app-to-database communication
- Service endpoints/private endpoints for security
- Monitoring across all tiers
- Scalability at each tier independently
