# Azure Networking Deep Dive - Complete Guide

## Virtual Network (VNet) Architecture

### VNet Fundamentals

**Address Space Planning:**
```
Enterprise VNet Structure:
10.0.0.0/8     - Entire Azure estate
├─ 10.0.0.0/16  - Production Hub (Region 1)
├─ 10.1.0.0/16  - Production Spoke 1
├─ 10.2.0.0/16  - Production Spoke 2
├─ 10.10.0.0/16 - Development Hub
├─ 10.20.0.0/16 - UAT Environment
└─ 10.30.0.0/16 - DR Region
```

### Subnet Design Patterns

**Production VNet (10.0.0.0/16):**
```
10.0.0.0/24   - GatewaySubnet (VPN/ExpressRoute Gateway)
10.0.1.0/24   - AzureFirewallSubnet (Azure Firewall)
10.0.2.0/24   - AzureBastionSubnet (Bastion Host)
10.0.3.0/24   - Management Subnet (Jump boxes, monitoring)
10.0.10.0/24  - Public Web Tier (Application Gateway)
10.0.11.0/24  - Private Web Tier (App Service VNet Integration)
10.0.20.0/24  - Application Tier (AKS System Nodes)
10.0.21.0/24  - Application Tier (AKS User Nodes)
10.0.22.0/24  - Application Tier (VMs)
10.0.30.0/24  - Data Tier (SQL MI)
10.0.31.0/24  - Data Tier (Private Endpoints)
10.0.40.0/24  - Integration Tier (Logic Apps, Functions)
10.0.50.0/24  - DMZ Subnet (NVA, Firewall)
```

### Complete Network Security Architecture

```
                        Internet
                           ↓
                    Azure DDoS Protection
                           ↓
                    Public IP (Standard)
                           ↓
    ┌──────────────────────┴──────────────────────┐
    ↓                                              ↓
Azure Front Door                          Azure Firewall
(Global WAF)                              (DNAT Rules)
    ↓                                              ↓
    └──────────────────────┬──────────────────────┘
                           ↓
                  Application Gateway
                  (Regional WAF)
                  Subnet: 10.0.10.0/24
                  NSG: AppGW-NSG
                           ↓
                  ┌────────┴────────┐
                  ↓                 ↓
          Public Subnet      Private Subnet
          10.0.11.0/24       10.0.20.0/24
          NSG: Web-NSG       NSG: App-NSG
                  ↓                 ↓
          App Service        AKS Cluster
          (VNet Integration) (Private Cluster)
                  ↓                 ↓
                  └────────┬────────┘
                           ↓
                  Private Subnet
                  10.0.30.0/24
                  NSG: Data-NSG
                           ↓
                  ┌────────┴────────┐
                  ↓                 ↓
          SQL Managed Instance  Private Endpoints
          (Private)             (Storage, Key Vault)
                           ↓
                  Service Endpoints
                  (Cosmos DB, Storage)
```

## Network Security Groups (NSG) - Detailed Rules

### Web Tier NSG (Web-NSG)

**Inbound Rules:**
```bash
# Allow HTTPS from Application Gateway
Priority: 100
Name: Allow-AppGW-HTTPS
Source: 10.0.10.0/24 (AppGW Subnet)
Destination: 10.0.11.0/24 (Web Subnet)
Port: 443
Protocol: TCP
Action: Allow

# Allow HTTP from Application Gateway
Priority: 110
Name: Allow-AppGW-HTTP
Source: 10.0.10.0/24
Destination: 10.0.11.0/24
Port: 80
Protocol: TCP
Action: Allow

# Allow Health Probes
Priority: 120
Name: Allow-AzureLoadBalancer
Source: AzureLoadBalancer
Destination: Any
Port: Any
Protocol: Any
Action: Allow

# Deny all other inbound
Priority: 4096
Name: Deny-All-Inbound
Source: Any
Destination: Any
Port: Any
Protocol: Any
Action: Deny
```

**Outbound Rules:**
```bash
# Allow to Application Tier
Priority: 100
Name: Allow-To-App-Tier
Source: 10.0.11.0/24
Destination: 10.0.20.0/24
Port: 8080, 8443
Protocol: TCP
Action: Allow

# Allow to Azure Services
Priority: 110
Name: Allow-To-Azure-Services
Source: 10.0.11.0/24
Destination: AzureCloud
Port: 443
Protocol: TCP
Action: Allow

# Deny all other outbound
Priority: 4096
Name: Deny-All-Outbound
Source: Any
Destination: Any
Port: Any
Protocol: Any
Action: Deny
```

### Application Tier NSG (App-NSG)

**Inbound Rules:**
```bash
# Allow from Web Tier
Priority: 100
Name: Allow-From-Web-Tier
Source: 10.0.11.0/24
Destination: 10.0.20.0/24
Port: 8080, 8443
Protocol: TCP
Action: Allow

# Allow from Application Gateway (for AKS ingress)
Priority: 110
Name: Allow-From-AppGW
Source: 10.0.10.0/24
Destination: 10.0.20.0/24
Port: 80, 443
Protocol: TCP
Action: Allow

# Allow internal AKS communication
Priority: 120
Name: Allow-AKS-Internal
Source: 10.0.20.0/23 (AKS subnets)
Destination: 10.0.20.0/23
Port: Any
Protocol: Any
Action: Allow

# Deny all other inbound
Priority: 4096
Name: Deny-All-Inbound
Source: Any
Destination: Any
Port: Any
Protocol: Any
Action: Deny
```

**Outbound Rules:**
```bash
# Allow to Data Tier
Priority: 100
Name: Allow-To-Data-Tier
Source: 10.0.20.0/24
Destination: 10.0.30.0/24
Port: 1433, 3306, 5432
Protocol: TCP
Action: Allow

# Allow to Private Endpoints
Priority: 110
Name: Allow-To-Private-Endpoints
Source: 10.0.20.0/24
Destination: 10.0.31.0/24
Port: 443
Protocol: TCP
Action: Allow

# Allow AKS to Azure Services
Priority: 120
Name: Allow-AKS-Azure-Services
Source: 10.0.20.0/24
Destination: AzureCloud
Port: 443, 9000
Protocol: TCP
Action: Allow

# Allow DNS
Priority: 130
Name: Allow-DNS
Source: 10.0.20.0/24
Destination: VirtualNetwork
Port: 53
Protocol: UDP
Action: Allow
```

### Data Tier NSG (Data-NSG)

**Inbound Rules:**
```bash
# Allow from Application Tier
Priority: 100
Name: Allow-From-App-Tier
Source: 10.0.20.0/23
Destination: 10.0.30.0/24
Port: 1433, 3306, 5432
Protocol: TCP
Action: Allow

# Allow from Management Subnet
Priority: 110
Name: Allow-From-Management
Source: 10.0.3.0/24
Destination: 10.0.30.0/24
Port: 1433, 3306, 5432, 22, 3389
Protocol: TCP
Action: Allow

# Deny all other inbound
Priority: 4096
Name: Deny-All-Inbound
Source: Any
Destination: Any
Port: Any
Protocol: Any
Action: Deny
```

**Outbound Rules:**
```bash
# Allow to Azure Backup
Priority: 100
Name: Allow-To-Backup
Source: 10.0.30.0/24
Destination: AzureBackup
Port: 443
Protocol: TCP
Action: Allow

# Allow to Storage (for backups)
Priority: 110
Name: Allow-To-Storage
Source: 10.0.30.0/24
Destination: Storage
Port: 443
Protocol: TCP
Action: Allow

# Deny all other outbound
Priority: 4096
Name: Deny-All-Outbound
Source: Any
Destination: Any
Port: Any
Protocol: Any
Action: Deny
```

## Azure Firewall Configuration

### Firewall Architecture

```
Hub VNet (10.0.0.0/16)
    ↓
AzureFirewallSubnet (10.0.1.0/24)
    ↓
Azure Firewall (Premium SKU)
├─ Threat Intelligence
├─ IDPS (Intrusion Detection/Prevention)
├─ TLS Inspection
└─ URL Filtering
    ↓
Route Tables (UDR)
├─ Web-Subnet-RT → 0.0.0.0/0 → Firewall
├─ App-Subnet-RT → 0.0.0.0/0 → Firewall
└─ Data-Subnet-RT → 0.0.0.0/0 → Firewall
```

### Firewall Rules

**Network Rules Collection:**
```bash
# Allow Web to App communication
Priority: 100
Name: Web-To-App-Rules
Rules:
  - Name: Allow-Web-To-AKS
    Source: 10.0.11.0/24
    Destination: 10.0.20.0/24
    Ports: 8080, 8443
    Protocol: TCP
    Action: Allow

# Allow App to Data communication
Priority: 110
Name: App-To-Data-Rules
Rules:
  - Name: Allow-App-To-SQL
    Source: 10.0.20.0/24
    Destination: 10.0.30.0/24
    Ports: 1433
    Protocol: TCP
    Action: Allow
  
  - Name: Allow-App-To-Cosmos
    Source: 10.0.20.0/24
    Destination: AzureCosmosDB
    Ports: 443, 10250-10255
    Protocol: TCP
    Action: Allow

# Allow outbound to Azure services
Priority: 120
Name: Azure-Services-Rules
Rules:
  - Name: Allow-To-AzureMonitor
    Source: 10.0.0.0/16
    Destination: AzureMonitor
    Ports: 443
    Protocol: TCP
    Action: Allow
  
  - Name: Allow-To-AzureKeyVault
    Source: 10.0.0.0/16
    Destination: AzureKeyVault
    Ports: 443
    Protocol: TCP
    Action: Allow
```

**Application Rules Collection:**
```bash
# Allow specific FQDNs
Priority: 200
Name: Allowed-FQDNs
Rules:
  - Name: Allow-Microsoft-Updates
    Source: 10.0.0.0/16
    Target FQDNs:
      - *.windowsupdate.microsoft.com
      - *.update.microsoft.com
      - *.microsoft.com
    Protocols: https:443
    Action: Allow
  
  - Name: Allow-AKS-Dependencies
    Source: 10.0.20.0/24
    Target FQDNs:
      - *.hcp.eastus.azmk8s.io
      - mcr.microsoft.com
      - *.data.mcr.microsoft.com
      - management.azure.com
      - login.microsoftonline.com
      - packages.microsoft.com
      - acs-mirror.azureedge.net
    Protocols: https:443
    Action: Allow
  
  - Name: Allow-External-APIs
    Source: 10.0.20.0/24
    Target FQDNs:
      - api.stripe.com
      - api.sendgrid.com
      - *.twilio.com
    Protocols: https:443
    Action: Allow

# Block malicious categories
Priority: 300
Name: Block-Categories
Rules:
  - Name: Block-Malicious-Sites
    Source: 10.0.0.0/16
    Web Categories:
      - Malware
      - Phishing
      - Adult Content
      - Gambling
    Action: Deny
```

**DNAT Rules (Inbound):**
```bash
# Allow HTTPS to Application Gateway
Priority: 100
Name: DNAT-To-AppGW
Rules:
  - Name: HTTPS-To-AppGW
    Source: Internet
    Destination: <Firewall-Public-IP>
    Destination Port: 443
    Translated Address: 10.0.10.10 (AppGW private IP)
    Translated Port: 443
    Protocol: TCP

# Allow SSH to Bastion (from specific IPs only)
Priority: 110
Name: DNAT-To-Bastion
Rules:
  - Name: SSH-To-Bastion
    Source: <Corporate-IP-Range>
    Destination: <Firewall-Public-IP>
    Destination Port: 22
    Translated Address: 10.0.2.10 (Bastion IP)
    Translated Port: 22
    Protocol: TCP
```

### Firewall Deployment

```bash
# Create Firewall
az network firewall create \
  --name prod-firewall \
  --resource-group network-rg \
  --location eastus \
  --sku AZFW_VNet \
  --tier Premium \
  --vnet-name hub-vnet \
  --public-ip prod-fw-pip

# Create Firewall Policy
az network firewall policy create \
  --name prod-fw-policy \
  --resource-group network-rg \
  --sku Premium \
  --threat-intel-mode Alert \
  --idps-mode Alert \
  --enable-dns-proxy true

# Associate policy with firewall
az network firewall update \
  --name prod-firewall \
  --resource-group network-rg \
  --firewall-policy prod-fw-policy
```

## Application Gateway with WAF

### Application Gateway Architecture

```
Internet
    ↓
Public IP (Standard, Zone-redundant)
    ↓
Application Gateway v2 (WAF_v2 SKU)
Subnet: 10.0.10.0/24
├─ Frontend Configuration
│  ├─ Public IP: 443 (HTTPS)
│  └─ Private IP: 10.0.10.10
├─ Backend Pools
│  ├─ Web-Pool: 10.0.11.10-15 (App Service)
│  ├─ API-Pool: 10.0.20.10 (AKS Ingress)
│  └─ Admin-Pool: 10.0.22.10 (VM)
├─ HTTP Settings
│  ├─ Cookie-based affinity
│  ├─ Connection draining
│  └─ Custom health probes
├─ Listeners
│  ├─ www.contoso.com:443 (Multi-site)
│  ├─ api.contoso.com:443 (Multi-site)
│  └─ admin.contoso.com:443 (Multi-site)
├─ Rules
│  ├─ Path-based routing
│  ├─ URL rewrite
│  └─ Redirect HTTP to HTTPS
└─ WAF Configuration
   ├─ OWASP 3.2 ruleset
   ├─ Prevention mode
   ├─ Custom rules
   └─ Exclusions
```

### WAF Configuration

**WAF Policy:**
```bash
# Create WAF Policy
az network application-gateway waf-policy create \
  --name prod-waf-policy \
  --resource-group network-rg \
  --location eastus

# Configure managed rules (OWASP)
az network application-gateway waf-policy managed-rule rule-set add \
  --policy-name prod-waf-policy \
  --resource-group network-rg \
  --type OWASP \
  --version 3.2

# Add Microsoft Bot Manager rules
az network application-gateway waf-policy managed-rule rule-set add \
  --policy-name prod-waf-policy \
  --resource-group network-rg \
  --type Microsoft_BotManagerRuleSet \
  --version 1.0
```

**Custom WAF Rules:**
```json
{
  "customRules": [
    {
      "name": "BlockSQLInjection",
      "priority": 10,
      "ruleType": "MatchRule",
      "action": "Block",
      "matchConditions": [
        {
          "matchVariables": [
            {
              "variableName": "RequestUri"
            },
            {
              "variableName": "QueryString"
            }
          ],
          "operator": "Contains",
          "matchValues": [
            "union select",
            "drop table",
            "exec(",
            "execute("
          ],
          "transforms": ["Lowercase"]
        }
      ]
    },
    {
      "name": "RateLimitPerIP",
      "priority": 20,
      "ruleType": "RateLimitRule",
      "action": "Block",
      "rateLimitDuration": "OneMin",
      "rateLimitThreshold": 100,
      "matchConditions": [
        {
          "matchVariables": [
            {
              "variableName": "RemoteAddr"
            }
          ],
          "operator": "IPMatch",
          "matchValues": ["0.0.0.0/0"]
        }
      ]
    },
    {
      "name": "BlockSpecificCountries",
      "priority": 30,
      "ruleType": "MatchRule",
      "action": "Block",
      "matchConditions": [
        {
          "matchVariables": [
            {
              "variableName": "RemoteAddr"
            }
          ],
          "operator": "GeoMatch",
          "matchValues": ["CN", "RU", "KP"]
        }
      ]
    },
    {
      "name": "AllowOnlyCorporateIP",
      "priority": 40,
      "ruleType": "MatchRule",
      "action": "Allow",
      "matchConditions": [
        {
          "matchVariables": [
            {
              "variableName": "RemoteAddr"
            }
          ],
          "operator": "IPMatch",
          "matchValues": [
            "203.0.113.0/24",
            "198.51.100.0/24"
          ]
        }
      ]
    }
  ]
}
```

### Application Gateway Configuration

```bash
# Create Application Gateway
az network application-gateway create \
  --name prod-appgw \
  --resource-group network-rg \
  --location eastus \
  --sku WAF_v2 \
  --capacity 2 \
  --min-capacity 2 \
  --max-capacity 10 \
  --vnet-name prod-vnet \
  --subnet appgw-subnet \
  --public-ip-address appgw-pip \
  --http-settings-cookie-based-affinity Enabled \
  --frontend-port 443 \
  --http-settings-port 443 \
  --http-settings-protocol Https \
  --priority 100 \
  --waf-policy prod-waf-policy

# Enable autoscale
az network application-gateway autoscale-config create \
  --gateway-name prod-appgw \
  --resource-group network-rg \
  --min-capacity 2 \
  --max-capacity 10

# Add SSL certificate
az network application-gateway ssl-cert create \
  --gateway-name prod-appgw \
  --resource-group network-rg \
  --name contoso-cert \
  --cert-file contoso.pfx \
  --cert-password <password>

# Create multi-site listener
az network application-gateway http-listener create \
  --gateway-name prod-appgw \
  --resource-group network-rg \
  --name www-listener \
  --frontend-port 443 \
  --host-name www.contoso.com \
  --ssl-cert contoso-cert

# Create backend pool
az network application-gateway address-pool create \
  --gateway-name prod-appgw \
  --resource-group network-rg \
  --name web-pool \
  --servers 10.0.11.10 10.0.11.11 10.0.11.12

# Create health probe
az network application-gateway probe create \
  --gateway-name prod-appgw \
  --resource-group network-rg \
  --name web-health-probe \
  --protocol Https \
  --host-name-from-http-settings true \
  --path /health \
  --interval 30 \
  --timeout 30 \
  --threshold 3

# Create URL path map (path-based routing)
az network application-gateway url-path-map create \
  --gateway-name prod-appgw \
  --resource-group network-rg \
  --name url-path-map \
  --paths /api/* \
  --address-pool api-pool \
  --default-address-pool web-pool \
  --http-settings appGatewayBackendHttpSettings
```

## Complete Enterprise Architecture Diagram

```
═══════════════════════════════════════════════════════════════════
                          INTERNET
═══════════════════════════════════════════════════════════════════
                              ↓
                    ┌─────────────────┐
                    │  Azure DDoS     │
                    │  Protection     │
                    └─────────────────┘
                              ↓
        ┌─────────────────────┴─────────────────────┐
        ↓                                           ↓
┌───────────────┐                          ┌───────────────┐
│ Azure Front   │                          │ Public IP     │
│ Door + WAF    │                          │ (Standard)    │
│ (Global)      │                          └───────┬───────┘
└───────┬───────┘                                  ↓
        │                              ┌───────────────────┐
        │                              │ Azure Firewall    │
        │                              │ Premium           │
        │                              │ 10.0.1.0/24       │
        │                              └─────────┬─────────┘
        │                                        │
        └────────────────┬───────────────────────┘
                         ↓
═══════════════════════════════════════════════════════════════════
                    HUB VNET (10.0.0.0/16)
═══════════════════════════════════════════════════════════════════
                         ↓
            ┌────────────────────────┐
            │  Application Gateway   │
            │  WAF_v2 (Zone-redundant)│
            │  10.0.10.0/24          │
            │  NSG: AppGW-NSG        │
            └────────────┬───────────┘
                         ↓
        ┌────────────────┴────────────────┐
        ↓                                 ↓
═══════════════════════════════════════════════════════════════════
              PUBLIC SUBNET          PRIVATE SUBNET
              10.0.11.0/24           10.0.20.0/24
              NSG: Web-NSG           NSG: App-NSG
═══════════════════════════════════════════════════════════════════
        ↓                                 ↓
┌───────────────┐                ┌───────────────────┐
│ App Service   │                │ AKS Private       │
│ (VNet Integ)  │                │ Cluster           │
│ - Web Apps    │                │ - System Pool     │
│ - API Apps    │                │ - User Pool       │
│               │                │ - Ingress (AGIC)  │
└───────┬───────┘                └─────────┬─────────┘
        │                                  │
        └──────────────┬───────────────────┘
                       ↓
═══════════════════════════════════════════════════════════════════
                  DATA TIER SUBNET
                  10.0.30.0/24
                  NSG: Data-NSG
═══════════════════════════════════════════════════════════════════
                       ↓
        ┌──────────────┴──────────────┐
        ↓                             ↓
┌───────────────┐            ┌────────────────┐
│ SQL Managed   │            │ Private        │
│ Instance      │            │ Endpoints      │
│ (Private)     │            │ 10.0.31.0/24   │
│               │            │                │
│ - Always On   │            │ - Storage      │
│ - TDE         │            │ - Key Vault    │
│ - Auditing    │            │ - Cosmos DB    │
└───────────────┘            │ - ACR          │
                             └────────────────┘
═══════════════════════════════════════════════════════════════════
                  MANAGEMENT SUBNET
                  10.0.3.0/24
                  NSG: Mgmt-NSG
═══════════════════════════════════════════════════════════════════
                       ↓
        ┌──────────────┴──────────────┐
        ↓                             ↓
┌───────────────┐            ┌────────────────┐
│ Azure Bastion │            │ Jump Box VMs   │
│ (Managed)     │            │ - Monitoring   │
│ 10.0.2.0/27   │            │ - Admin Tools  │
└───────────────┘            └────────────────┘
═══════════════════════════════════════════════════════════════════
                  CONNECTIVITY
═══════════════════════════════════════════════════════════════════
┌───────────────┐            ┌────────────────┐
│ VPN Gateway   │            │ ExpressRoute   │
│ (Zone-redund) │            │ Gateway        │
│ 10.0.0.0/27   │            │ (Ultra Perf)   │
│               │            │                │
│ - S2S VPN     │            │ - Private      │
│ - P2S VPN     │            │   Peering      │
└───────┬───────┘            └────────┬───────┘
        │                             │
        └──────────┬──────────────────┘
                   ↓
           On-Premises Network
═══════════════════════════════════════════════════════════════════
```

## Traffic Flow Examples

### Inbound HTTPS Request Flow

```
1. User (Internet)
   ↓ HTTPS (443)
2. Azure DDoS Protection
   ↓ (DDoS mitigation)
3. Azure Front Door
   ↓ (Global load balancing, WAF inspection)
4. Azure Firewall
   ↓ (DNAT rule, threat intelligence)
5. Application Gateway (10.0.10.10)
   ↓ (WAF inspection, SSL termination, routing)
6. Backend Pool
   ├─ App Service (10.0.11.10) [Web-NSG allows from AppGW]
   └─ AKS Ingress (10.0.20.10) [App-NSG allows from AppGW]
   ↓
7. Application Logic
   ↓ (App-NSG allows to Data tier)
8. SQL Managed Instance (10.0.30.10)
   ↓ [Data-NSG allows from App tier]
9. Response back through same path
```

### Outbound Internet Request Flow

```
1. AKS Pod (10.0.20.50)
   ↓ (Needs to call external API)
2. Route Table (UDR)
   ↓ (0.0.0.0/0 → Azure Firewall)
3. Azure Firewall (10.0.1.4)
   ↓ (Application rule check)
4. Firewall Public IP
   ↓ (SNAT)
5. Internet (api.stripe.com)
   ↓
6. Response back through Firewall
   ↓
7. AKS Pod (10.0.20.50)
```

### Internal Service-to-Service Flow

```
1. Web App (10.0.11.10)
   ↓ HTTPS (8443)
2. Web-NSG (Outbound rule check)
   ↓ (Allows to App tier)
3. AKS Service (10.0.20.30)
   ↓ (App-NSG Inbound rule check)
4. App-NSG (Allows from Web tier)
   ↓
5. Pod processes request
   ↓ SQL (1433)
6. App-NSG (Outbound rule check)
   ↓ (Allows to Data tier)
7. SQL MI (10.0.30.10)
   ↓ (Data-NSG Inbound rule check)
8. Data-NSG (Allows from App tier)
   ↓
9. Query execution
   ↓
10. Response back through same path
```

## Key Takeaways

✅ **Defense in Depth:** Multiple security layers (DDoS, Firewall, WAF, NSG)  
✅ **Subnet Segmentation:** Separate subnets for each tier with specific NSGs  
✅ **Private Endpoints:** Keep data services off public internet  
✅ **Hub-Spoke Topology:** Centralized security and connectivity  
✅ **Zero Trust:** Explicit allow rules, deny by default  
✅ **Forced Tunneling:** Route all traffic through firewall with UDRs  
✅ **WAF Protection:** OWASP rules + custom rules for application security  
✅ **Network Monitoring:** Enable NSG flow logs and Traffic Analytics  
✅ **Least Privilege:** Minimal required ports and protocols only  
✅ **Zone Redundancy:** Deploy critical components across availability zones
