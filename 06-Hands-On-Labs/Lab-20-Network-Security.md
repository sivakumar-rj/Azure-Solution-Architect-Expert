# Lab 20: Network Security

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Virtual network with resources
- Basic security knowledge

## Objective
Implement network security with NSGs, Azure Firewall, and DDoS protection.

---

## Configure Network Security Groups

```bash
# Create NSG
az network nsg create \
  --resource-group rg-security-lab \
  --name nsg-web-tier

# Add inbound rules
az network nsg rule create \
  --resource-group rg-security-lab \
  --nsg-name nsg-web-tier \
  --name Allow-HTTP \
  --priority 100 \
  --source-address-prefixes Internet \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow

az network nsg rule create \
  --resource-group rg-security-lab \
  --nsg-name nsg-web-tier \
  --name Allow-HTTPS \
  --priority 110 \
  --source-address-prefixes Internet \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow

# Add outbound rule
az network nsg rule create \
  --resource-group rg-security-lab \
  --nsg-name nsg-web-tier \
  --name Deny-Internet \
  --priority 4000 \
  --direction Outbound \
  --source-address-prefixes '*' \
  --destination-address-prefixes Internet \
  --protocol '*' \
  --access Deny

# Associate with subnet
az network vnet subnet update \
  --resource-group rg-security-lab \
  --vnet-name vnet-app \
  --name subnet-web \
  --network-security-group nsg-web-tier
```

---

## Configure Azure Firewall

```bash
# Create firewall subnet
az network vnet subnet create \
  --resource-group rg-security-lab \
  --vnet-name vnet-hub \
  --name AzureFirewallSubnet \
  --address-prefix 10.0.100.0/26

# Create public IP
az network public-ip create \
  --resource-group rg-security-lab \
  --name pip-firewall \
  --sku Standard \
  --allocation-method Static

# Create firewall
az network firewall create \
  --resource-group rg-security-lab \
  --name fw-hub \
  --location eastus

# Configure firewall
az network firewall ip-config create \
  --resource-group rg-security-lab \
  --firewall-name fw-hub \
  --name fw-config \
  --public-ip-address pip-firewall \
  --vnet-name vnet-hub

# Get firewall private IP
FW_PRIVATE_IP=$(az network firewall show \
  --resource-group rg-security-lab \
  --name fw-hub \
  --query 'ipConfigurations[0].privateIPAddress' -o tsv)
```

---

## Configure Firewall Rules

```bash
# Create application rule collection
az network firewall application-rule create \
  --resource-group rg-security-lab \
  --firewall-name fw-hub \
  --collection-name app-rules \
  --name Allow-Microsoft \
  --protocols Http=80 Https=443 \
  --source-addresses 10.0.0.0/16 \
  --target-fqdns *.microsoft.com *.windows.net \
  --priority 100 \
  --action Allow

# Create network rule collection
az network firewall network-rule create \
  --resource-group rg-security-lab \
  --firewall-name fw-hub \
  --collection-name net-rules \
  --name Allow-DNS \
  --protocols UDP \
  --source-addresses 10.0.0.0/16 \
  --destination-addresses '*' \
  --destination-ports 53 \
  --priority 200 \
  --action Allow

# Create NAT rule collection
az network firewall nat-rule create \
  --resource-group rg-security-lab \
  --firewall-name fw-hub \
  --collection-name nat-rules \
  --name DNAT-HTTP \
  --protocols TCP \
  --source-addresses '*' \
  --destination-addresses <FIREWALL_PUBLIC_IP> \
  --destination-ports 80 \
  --translated-address 10.0.1.4 \
  --translated-port 80 \
  --priority 300 \
  --action Dnat
```

---

## Configure Route Table

```bash
# Create route table
az network route-table create \
  --resource-group rg-security-lab \
  --name rt-firewall

# Add route to firewall
az network route-table route create \
  --resource-group rg-security-lab \
  --route-table-name rt-firewall \
  --name route-to-internet \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $FW_PRIVATE_IP

# Associate with subnet
az network vnet subnet update \
  --resource-group rg-security-lab \
  --vnet-name vnet-app \
  --name subnet-web \
  --route-table rt-firewall
```

---

## Configure DDoS Protection

```bash
# Create DDoS protection plan
az network ddos-protection create \
  --resource-group rg-security-lab \
  --name ddos-plan \
  --location eastus

# Enable on VNet
az network vnet update \
  --resource-group rg-security-lab \
  --name vnet-app \
  --ddos-protection true \
  --ddos-protection-plan ddos-plan
```

---

## Configure Azure Bastion

```bash
# Create Bastion subnet
az network vnet subnet create \
  --resource-group rg-security-lab \
  --vnet-name vnet-app \
  --name AzureBastionSubnet \
  --address-prefix 10.0.10.0/27

# Create public IP
az network public-ip create \
  --resource-group rg-security-lab \
  --name pip-bastion \
  --sku Standard

# Create Bastion
az network bastion create \
  --resource-group rg-security-lab \
  --name bastion-app \
  --public-ip-address pip-bastion \
  --vnet-name vnet-app \
  --location eastus
```

---

## Configure Web Application Firewall

```bash
# Create WAF policy
az network application-gateway waf-policy create \
  --resource-group rg-security-lab \
  --name waf-policy

# Configure managed rules
az network application-gateway waf-policy managed-rule rule-set add \
  --resource-group rg-security-lab \
  --policy-name waf-policy \
  --type OWASP \
  --version 3.2

# Create custom rule
az network application-gateway waf-policy custom-rule create \
  --resource-group rg-security-lab \
  --policy-name waf-policy \
  --name BlockBadBots \
  --priority 100 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions "RequestHeaders" "User-Agent" "Contains" "badbot"
```

---

## Configure Network Watcher

```bash
# Enable Network Watcher
az network watcher configure \
  --resource-group NetworkWatcherRG \
  --locations eastus \
  --enabled true

# Enable NSG flow logs
az network watcher flow-log create \
  --resource-group rg-security-lab \
  --name nsg-flow-log \
  --nsg nsg-web-tier \
  --storage-account <STORAGE_ACCOUNT_ID> \
  --enabled true \
  --retention 30 \
  --traffic-analytics true \
  --workspace <LOG_ANALYTICS_WORKSPACE_ID>

# Test connectivity
az network watcher test-connectivity \
  --resource-group rg-security-lab \
  --source-resource <VM1_ID> \
  --dest-resource <VM2_ID> \
  --protocol Tcp \
  --dest-port 80
```

---

## Key Takeaways
- NSGs provide basic firewall functionality
- Azure Firewall is centralized network security
- DDoS Protection defends against attacks
- Azure Bastion provides secure remote access
- WAF protects web applications
- Network Watcher monitors and diagnoses
- Defense in depth with multiple layers
