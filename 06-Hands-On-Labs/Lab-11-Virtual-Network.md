# Lab 11: Virtual Network

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI
- Basic networking knowledge

## Objective
Create and configure Azure Virtual Networks with subnets, NSGs, and peering.

---

## Create Virtual Network

```bash
# Create resource group
az group create --name rg-vnet-lab --location eastus

# Create VNet with subnet
az network vnet create \
  --resource-group rg-vnet-lab \
  --name vnet-hub \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-web \
  --subnet-prefix 10.0.1.0/24

# Add additional subnets
az network vnet subnet create \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name subnet-app \
  --address-prefix 10.0.2.0/24

az network vnet subnet create \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name subnet-db \
  --address-prefix 10.0.3.0/24
```

---

## Configure Network Security Groups

```bash
# Create NSG
az network nsg create \
  --resource-group rg-vnet-lab \
  --name nsg-web

# Add rules
az network nsg rule create \
  --resource-group rg-vnet-lab \
  --nsg-name nsg-web \
  --name AllowHTTP \
  --priority 100 \
  --source-address-prefixes '*' \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow

az network nsg rule create \
  --resource-group rg-vnet-lab \
  --nsg-name nsg-web \
  --name AllowHTTPS \
  --priority 110 \
  --source-address-prefixes '*' \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow

# Associate NSG with subnet
az network vnet subnet update \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name subnet-web \
  --network-security-group nsg-web
```

---

## Configure VNet Peering

```bash
# Create second VNet
az network vnet create \
  --resource-group rg-vnet-lab \
  --name vnet-spoke \
  --address-prefix 10.1.0.0/16 \
  --subnet-name subnet-default \
  --subnet-prefix 10.1.1.0/24

# Create peering from hub to spoke
az network vnet peering create \
  --resource-group rg-vnet-lab \
  --name hub-to-spoke \
  --vnet-name vnet-hub \
  --remote-vnet vnet-spoke \
  --allow-vnet-access

# Create peering from spoke to hub
az network vnet peering create \
  --resource-group rg-vnet-lab \
  --name spoke-to-hub \
  --vnet-name vnet-spoke \
  --remote-vnet vnet-hub \
  --allow-vnet-access
```

---

## Configure Service Endpoints

```bash
# Enable service endpoint for Storage
az network vnet subnet update \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name subnet-app \
  --service-endpoints Microsoft.Storage Microsoft.Sql
```

---

## Configure Private Endpoints

```bash
# Create storage account
az storage account create \
  --name stprivate$RANDOM \
  --resource-group rg-vnet-lab \
  --location eastus \
  --sku Standard_LRS

# Disable public access
az storage account update \
  --name stprivate$RANDOM \
  --resource-group rg-vnet-lab \
  --public-network-access Disabled

# Create private endpoint
az network private-endpoint create \
  --resource-group rg-vnet-lab \
  --name pe-storage \
  --vnet-name vnet-hub \
  --subnet subnet-app \
  --private-connection-resource-id <STORAGE_ACCOUNT_ID> \
  --group-id blob \
  --connection-name storage-connection
```

---

## Configure Route Tables

```bash
# Create route table
az network route-table create \
  --resource-group rg-vnet-lab \
  --name rt-custom

# Add route
az network route-table route create \
  --resource-group rg-vnet-lab \
  --route-table-name rt-custom \
  --name route-to-firewall \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address 10.0.4.4

# Associate with subnet
az network vnet subnet update \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name subnet-web \
  --route-table rt-custom
```

---

## Configure Azure Bastion

```bash
# Create Bastion subnet
az network vnet subnet create \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name AzureBastionSubnet \
  --address-prefix 10.0.10.0/27

# Create public IP
az network public-ip create \
  --resource-group rg-vnet-lab \
  --name pip-bastion \
  --sku Standard

# Create Bastion
az network bastion create \
  --resource-group rg-vnet-lab \
  --name bastion-hub \
  --public-ip-address pip-bastion \
  --vnet-name vnet-hub \
  --location eastus
```

---

## Configure NAT Gateway

```bash
# Create public IP
az network public-ip create \
  --resource-group rg-vnet-lab \
  --name pip-nat \
  --sku Standard

# Create NAT gateway
az network nat gateway create \
  --resource-group rg-vnet-lab \
  --name nat-gateway \
  --public-ip-addresses pip-nat \
  --idle-timeout 10

# Associate with subnet
az network vnet subnet update \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --name subnet-app \
  --nat-gateway nat-gateway
```

---

## Verification Steps

```bash
# List VNets
az network vnet list --resource-group rg-vnet-lab --output table

# Check peering status
az network vnet peering list \
  --resource-group rg-vnet-lab \
  --vnet-name vnet-hub \
  --output table

# Test connectivity
az network watcher test-connectivity \
  --resource-group rg-vnet-lab \
  --source-resource <VM1_ID> \
  --dest-resource <VM2_ID> \
  --protocol Tcp \
  --dest-port 80
```

---

## Troubleshooting

**Issue: Peering not working**
- Verify both peerings are created
- Check address spaces don't overlap
- Ensure allow-vnet-access is enabled

**Issue: Cannot access resources**
- Check NSG rules
- Verify route tables
- Check service endpoint configuration

---

## Cleanup

```bash
az group delete --name rg-vnet-lab --yes --no-wait
```

---

## Key Takeaways
- VNets provide network isolation
- Subnets segment VNet address space
- NSGs control traffic at subnet/NIC level
- VNet peering connects VNets
- Service endpoints secure Azure services
- Private endpoints provide private IP access
- Azure Bastion enables secure RDP/SSH
