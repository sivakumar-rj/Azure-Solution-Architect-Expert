# Lab 13: Application Gateway

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Backend web servers or App Services
- SSL certificate (optional)

## Objective
Deploy Azure Application Gateway with WAF, SSL termination, and URL routing.

---

## Create Application Gateway

```bash
# Create resource group
az group create --name rg-appgw-lab --location eastus

# Create VNet
az network vnet create \
  --resource-group rg-appgw-lab \
  --name vnet-appgw \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-appgw \
  --subnet-prefix 10.0.1.0/24

# Create backend subnet
az network vnet subnet create \
  --resource-group rg-appgw-lab \
  --vnet-name vnet-appgw \
  --name subnet-backend \
  --address-prefix 10.0.2.0/24

# Create public IP
az network public-ip create \
  --resource-group rg-appgw-lab \
  --name pip-appgw \
  --sku Standard \
  --allocation-method Static

# Create Application Gateway
az network application-gateway create \
  --resource-group rg-appgw-lab \
  --name appgw-web \
  --location eastus \
  --vnet-name vnet-appgw \
  --subnet subnet-appgw \
  --public-ip-address pip-appgw \
  --sku WAF_v2 \
  --capacity 2 \
  --http-settings-cookie-based-affinity Disabled \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --frontend-port 80 \
  --servers 10.0.2.4 10.0.2.5
```

---

## Configure WAF

```bash
# Enable WAF
az network application-gateway waf-config set \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-type OWASP \
  --rule-set-version 3.2

# Create custom WAF rule
az network application-gateway waf-policy custom-rule create \
  --resource-group rg-appgw-lab \
  --policy-name waf-policy \
  --name BlockSQLInjection \
  --priority 100 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions "RequestHeaders" "User-Agent" "Contains" "sqlmap"
```

---

## Configure SSL/TLS

```bash
# Upload SSL certificate
az network application-gateway ssl-cert create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name ssl-cert \
  --cert-file certificate.pfx \
  --cert-password <PASSWORD>

# Create HTTPS listener
az network application-gateway http-listener create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name listener-https \
  --frontend-port 443 \
  --ssl-cert ssl-cert

# Create routing rule
az network application-gateway rule create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name rule-https \
  --http-listener listener-https \
  --rule-type Basic \
  --address-pool appGatewayBackendPool \
  --http-settings appGatewayBackendHttpSettings
```

---

## Configure URL Path-Based Routing

```bash
# Create backend pools
az network application-gateway address-pool create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name pool-images \
  --servers 10.0.2.10

az network application-gateway address-pool create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name pool-videos \
  --servers 10.0.2.11

# Create URL path map
az network application-gateway url-path-map create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name url-path-map \
  --paths /images/* \
  --address-pool pool-images \
  --default-address-pool appGatewayBackendPool \
  --http-settings appGatewayBackendHttpSettings

# Add path rule
az network application-gateway url-path-map rule create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --path-map-name url-path-map \
  --name rule-videos \
  --paths /videos/* \
  --address-pool pool-videos \
  --http-settings appGatewayBackendHttpSettings
```

---

## Configure Health Probes

```bash
# Create custom health probe
az network application-gateway probe create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name health-probe \
  --protocol Http \
  --host-name-from-http-settings true \
  --path /health \
  --interval 30 \
  --timeout 30 \
  --threshold 3

# Update backend settings to use probe
az network application-gateway http-settings update \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name appGatewayBackendHttpSettings \
  --probe health-probe
```

---

## Configure Autoscaling

```bash
# Enable autoscaling
az network application-gateway update \
  --resource-group rg-appgw-lab \
  --name appgw-web \
  --min-capacity 2 \
  --max-capacity 10
```

---

## Configure Rewrite Rules

```bash
# Create rewrite rule set
az network application-gateway rewrite-rule set create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --name rewrite-set

# Add rewrite rule
az network application-gateway rewrite-rule create \
  --resource-group rg-appgw-lab \
  --gateway-name appgw-web \
  --rule-set-name rewrite-set \
  --name add-security-headers \
  --sequence 100 \
  --response-headers X-Frame-Options=DENY X-Content-Type-Options=nosniff
```

---

## Verification Steps

```bash
# Get public IP
APPGW_IP=$(az network public-ip show \
  --resource-group rg-appgw-lab \
  --name pip-appgw \
  --query ipAddress -o tsv)

# Test Application Gateway
curl http://$APPGW_IP
curl http://$APPGW_IP/images/test.jpg
curl http://$APPGW_IP/videos/test.mp4

# Check backend health
az network application-gateway show-backend-health \
  --resource-group rg-appgw-lab \
  --name appgw-web
```

---

## Cleanup

```bash
az group delete --name rg-appgw-lab --yes --no-wait
```

---

## Key Takeaways
- Layer 7 load balancer with URL routing
- WAF protects against web vulnerabilities
- SSL termination offloads encryption
- Autoscaling based on traffic
- Custom health probes monitor backends
- Rewrite rules modify headers
- Supports multi-site hosting
