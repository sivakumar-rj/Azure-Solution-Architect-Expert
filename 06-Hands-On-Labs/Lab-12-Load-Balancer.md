# Lab 12: Load Balancer

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Basic networking knowledge
- VMs or VM Scale Set

## Objective
Configure Azure Load Balancer for high availability and traffic distribution.

---

## Create Standard Load Balancer

```bash
# Create resource group
az group create --name rg-lb-lab --location eastus

# Create VNet
az network vnet create \
  --resource-group rg-lb-lab \
  --name vnet-lb \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-backend \
  --subnet-prefix 10.0.1.0/24

# Create public IP
az network public-ip create \
  --resource-group rg-lb-lab \
  --name pip-lb \
  --sku Standard \
  --allocation-method Static

# Create load balancer
az network lb create \
  --resource-group rg-lb-lab \
  --name lb-web \
  --sku Standard \
  --public-ip-address pip-lb \
  --frontend-ip-name frontend-lb \
  --backend-pool-name backend-pool

# Create health probe
az network lb probe create \
  --resource-group rg-lb-lab \
  --lb-name lb-web \
  --name health-probe \
  --protocol Http \
  --port 80 \
  --path /

# Create load balancing rule
az network lb rule create \
  --resource-group rg-lb-lab \
  --lb-name lb-web \
  --name lb-rule-http \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name frontend-lb \
  --backend-pool-name backend-pool \
  --probe-name health-probe

# Create NAT rules for SSH
az network lb inbound-nat-rule create \
  --resource-group rg-lb-lab \
  --lb-name lb-web \
  --name nat-rule-vm1 \
  --protocol Tcp \
  --frontend-port 50001 \
  --backend-port 22 \
  --frontend-ip-name frontend-lb
```

---

## Create Backend VMs

```bash
# Create availability set
az vm availability-set create \
  --resource-group rg-lb-lab \
  --name avset-web \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 5

# Create VMs
for i in 1 2; do
  az vm create \
    --resource-group rg-lb-lab \
    --name vm-web-$i \
    --availability-set avset-web \
    --vnet-name vnet-lb \
    --subnet subnet-backend \
    --image Ubuntu2204 \
    --size Standard_B1s \
    --admin-username azureuser \
    --generate-ssh-keys \
    --public-ip-address "" \
    --nsg ""
  
  # Install web server
  az vm run-command invoke \
    --resource-group rg-lb-lab \
    --name vm-web-$i \
    --command-id RunShellScript \
    --scripts "sudo apt-get update && sudo apt-get install -y nginx && echo 'Server $i' | sudo tee /var/www/html/index.html"
done

# Add VMs to backend pool
for i in 1 2; do
  NIC_ID=$(az vm show --resource-group rg-lb-lab --name vm-web-$i --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  az network nic ip-config address-pool add \
    --resource-group rg-lb-lab \
    --nic-name $(basename $NIC_ID) \
    --ip-config-name ipconfig1 \
    --lb-name lb-web \
    --address-pool backend-pool
done
```

---

## Configure Internal Load Balancer

```bash
# Create internal load balancer
az network lb create \
  --resource-group rg-lb-lab \
  --name lb-internal \
  --sku Standard \
  --vnet-name vnet-lb \
  --subnet subnet-backend \
  --frontend-ip-name frontend-internal \
  --backend-pool-name backend-pool-internal \
  --private-ip-address 10.0.1.10

# Create health probe
az network lb probe create \
  --resource-group rg-lb-lab \
  --lb-name lb-internal \
  --name health-probe-internal \
  --protocol Tcp \
  --port 80

# Create load balancing rule
az network lb rule create \
  --resource-group rg-lb-lab \
  --lb-name lb-internal \
  --name lb-rule-internal \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name frontend-internal \
  --backend-pool-name backend-pool-internal \
  --probe-name health-probe-internal
```

---

## Configure Outbound Rules

```bash
# Create outbound public IP
az network public-ip create \
  --resource-group rg-lb-lab \
  --name pip-outbound \
  --sku Standard

# Add outbound frontend
az network lb frontend-ip create \
  --resource-group rg-lb-lab \
  --lb-name lb-web \
  --name frontend-outbound \
  --public-ip-address pip-outbound

# Create outbound rule
az network lb outbound-rule create \
  --resource-group rg-lb-lab \
  --lb-name lb-web \
  --name outbound-rule \
  --frontend-ip-configs frontend-outbound \
  --protocol All \
  --idle-timeout 15 \
  --outbound-ports 10000 \
  --address-pool backend-pool
```

---

## Configure Session Persistence

```bash
# Update rule with session persistence
az network lb rule update \
  --resource-group rg-lb-lab \
  --lb-name lb-web \
  --name lb-rule-http \
  --load-distribution SourceIP
```

---

## Configure HA Ports

```bash
# Create HA ports rule (internal LB only)
az network lb rule create \
  --resource-group rg-lb-lab \
  --lb-name lb-internal \
  --name ha-ports-rule \
  --protocol All \
  --frontend-port 0 \
  --backend-port 0 \
  --frontend-ip-name frontend-internal \
  --backend-pool-name backend-pool-internal
```

---

## Verification Steps

```bash
# Get public IP
LB_IP=$(az network public-ip show \
  --resource-group rg-lb-lab \
  --name pip-lb \
  --query ipAddress -o tsv)

# Test load balancer
for i in {1..10}; do
  curl http://$LB_IP
  sleep 1
done

# Check backend health
az network lb show \
  --resource-group rg-lb-lab \
  --name lb-web

# View metrics
az monitor metrics list \
  --resource <LB_RESOURCE_ID> \
  --metric ByteCount \
  --output table
```

---

## Troubleshooting

**Issue: Backend unhealthy**
- Check health probe configuration
- Verify backend service is running
- Check NSG rules allow health probe traffic

**Issue: Uneven distribution**
- Verify session persistence settings
- Check backend VM capacity
- Review load distribution algorithm

**Issue: Connection timeouts**
- Increase idle timeout
- Check backend application response time
- Verify NSG and firewall rules

---

## Cleanup

```bash
az group delete --name rg-lb-lab --yes --no-wait
```

---

## Key Takeaways
- Standard LB supports zone redundancy
- Health probes monitor backend health
- Session persistence maintains client affinity
- Internal LB for private traffic
- Outbound rules control egress traffic
- HA ports simplify NVA scenarios
- Supports TCP and UDP protocols
