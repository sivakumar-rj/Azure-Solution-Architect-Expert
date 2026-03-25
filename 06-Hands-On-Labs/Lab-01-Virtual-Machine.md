# Lab 01: Virtual Machine

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI installed or Azure Cloud Shell access
- Basic understanding of networking concepts

## Objective
Deploy and configure an Azure Virtual Machine using Portal, CLI, and PowerShell methods.

---

## Method 1: Azure Portal

### Step 1: Create Resource Group
1. Navigate to Azure Portal (portal.azure.com)
2. Search for "Resource groups" → Click "Create"
3. Fill in details:
   - Subscription: Select your subscription
   - Resource group: `rg-vm-lab`
   - Region: `East US`
4. Click "Review + Create" → "Create"

### Step 2: Create Virtual Machine
1. Search for "Virtual machines" → Click "Create" → "Azure virtual machine"
2. **Basics tab:**
   - Resource group: `rg-vm-lab`
   - VM name: `vm-web-01`
   - Region: `East US`
   - Availability: No infrastructure redundancy required
   - Image: `Ubuntu Server 22.04 LTS`
   - Size: `Standard_B2s`
   - Authentication: SSH public key
   - Username: `azureuser`
   - Key pair name: `vm-web-01_key`
3. **Disks tab:**
   - OS disk type: `Standard SSD`
4. **Networking tab:**
   - Virtual network: Create new → `vnet-lab`
   - Subnet: `default (10.0.0.0/24)`
   - Public IP: Create new → `vm-web-01-ip`
   - NIC NSG: `Basic`
   - Public inbound ports: `SSH (22)`
5. **Management tab:**
   - Enable auto-shutdown: `Yes` (7:00 PM)
6. Click "Review + Create" → "Create"
7. Download the private key when prompted

### Step 3: Connect to VM
```bash
chmod 400 vm-web-01_key.pem
ssh -i vm-web-01_key.pem azureuser@<PUBLIC_IP>
```

---

## Method 2: Azure CLI

```bash
# Create resource group
az group create --name rg-vm-lab-cli --location eastus

# Create virtual network
az network vnet create \
  --resource-group rg-vm-lab-cli \
  --name vnet-lab \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.0.0/24

# Create public IP
az network public-ip create \
  --resource-group rg-vm-lab-cli \
  --name vm-web-01-ip \
  --sku Standard

# Create NSG
az network nsg create \
  --resource-group rg-vm-lab-cli \
  --name vm-web-01-nsg

# Add SSH rule
az network nsg rule create \
  --resource-group rg-vm-lab-cli \
  --nsg-name vm-web-01-nsg \
  --name AllowSSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow

# Create VM
az vm create \
  --resource-group rg-vm-lab-cli \
  --name vm-web-01 \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-address vm-web-01-ip \
  --nsg vm-web-01-nsg \
  --vnet-name vnet-lab \
  --subnet default

# Get public IP
az vm show -d --resource-group rg-vm-lab-cli --name vm-web-01 --query publicIps -o tsv
```

---

## Method 3: PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-vm-lab-ps" -Location "EastUS"

# Create network security group rule
$nsgRule = New-AzNetworkSecurityRuleConfig `
  -Name "AllowSSH" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access Allow

# Create NSG
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName "rg-vm-lab-ps" `
  -Location "EastUS" `
  -Name "vm-web-01-nsg" `
  -SecurityRules $nsgRule

# Create subnet
$subnet = New-AzVirtualNetworkSubnetConfig `
  -Name "default" `
  -AddressPrefix "10.0.0.0/24"

# Create virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName "rg-vm-lab-ps" `
  -Location "EastUS" `
  -Name "vnet-lab" `
  -AddressPrefix "10.0.0.0/16" `
  -Subnet $subnet

# Create public IP
$pip = New-AzPublicIpAddress `
  -ResourceGroupName "rg-vm-lab-ps" `
  -Location "EastUS" `
  -Name "vm-web-01-ip" `
  -AllocationMethod Static `
  -Sku Standard

# Create NIC
$nic = New-AzNetworkInterface `
  -ResourceGroupName "rg-vm-lab-ps" `
  -Location "EastUS" `
  -Name "vm-web-01-nic" `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Create VM configuration
$vmConfig = New-AzVMConfig -VMName "vm-web-01" -VMSize "Standard_B2s" | `
  Set-AzVMOperatingSystem -Linux -ComputerName "vm-web-01" -Credential (Get-Credential) | `
  Set-AzVMSourceImage -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest" | `
  Add-AzVMNetworkInterface -Id $nic.Id

# Create VM
New-AzVM -ResourceGroupName "rg-vm-lab-ps" -Location "EastUS" -VM $vmConfig
```

---

## Verification Steps

1. **Check VM status:**
```bash
az vm get-instance-view --resource-group rg-vm-lab-cli --name vm-web-01 --query instanceView.statuses[1].displayStatus
```

2. **Test SSH connectivity:**
```bash
ssh azureuser@<PUBLIC_IP>
```

3. **Verify VM details:**
```bash
# Inside VM
uname -a
df -h
free -m
```

---

## Troubleshooting

**Issue: Cannot connect via SSH**
- Verify NSG rules allow port 22
- Check public IP is assigned
- Ensure SSH key permissions: `chmod 400 <key>.pem`

**Issue: VM creation fails**
- Verify quota limits in subscription
- Check region availability for VM size
- Ensure unique resource names

**Issue: Slow performance**
- Check VM size meets workload requirements
- Monitor CPU/memory usage in Azure Portal
- Consider upgrading to higher tier

---

## Cleanup

```bash
# Delete resource group (removes all resources)
az group delete --name rg-vm-lab-cli --yes --no-wait
az group delete --name rg-vm-lab-ps --yes --no-wait
```

---

## Key Takeaways
- Azure VMs support multiple deployment methods
- NSG rules control network access
- SSH keys provide secure authentication
- Resource groups simplify resource management
- Always clean up resources to avoid costs
