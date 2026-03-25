# Azure Hands-On Labs

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## 📚 Lab Overview

This folder contains step-by-step hands-on labs for Azure Solution Architect Expert certification preparation.

## 🎯 Lab Structure

### Compute Labs
- **[Lab-01-Virtual-Machine.md](./Lab-01-Virtual-Machine.md)** - Create and configure Azure VMs
- **[Lab-02-App-Service.md](./Lab-02-App-Service.md)** - Deploy web apps to Azure App Service

### Storage Labs
- **[Lab-03-Storage-Account.md](./Lab-03-Storage-Account.md)** - Blob storage, lifecycle management, static websites
- **[Lab-04-Azure-Files.md](./Lab-04-Azure-Files.md)** - File shares and SMB access

### Container Labs
- **[Lab-05-Docker-Basics.md](./Lab-05-Docker-Basics.md)** - Docker containerization and ACR
- **[Lab-06-AKS-Deployment.md](./Lab-06-AKS-Deployment.md)** - Deploy and manage AKS clusters
- **[Lab-07-AKS-Advanced.md](./Lab-07-AKS-Advanced.md)** - Ingress, autoscaling, monitoring

### Database Labs
- **[Lab-08-Azure-SQL.md](./Lab-08-Azure-SQL.md)** - Azure SQL Database deployment
- **[Lab-09-MySQL-Database.md](./Lab-09-MySQL-Database.md)** - MySQL Flexible Server
- **[Lab-10-Cosmos-DB.md](./Lab-10-Cosmos-DB.md)** - NoSQL with Cosmos DB

### Networking Labs
- **[Lab-11-Virtual-Network.md](./Lab-11-Virtual-Network.md)** - VNet, subnets, NSG, peering
- **[Lab-12-Load-Balancer.md](./Lab-12-Load-Balancer.md)** - Load balancing and traffic distribution
- **[Lab-13-Application-Gateway.md](./Lab-13-Application-Gateway.md)** - Layer 7 load balancing
- **[Lab-14-Azure-CDN.md](./Lab-14-Azure-CDN.md)** - Content delivery network

### DevOps Labs
- **[Lab-15-Azure-DevOps-Setup.md](./Lab-15-Azure-DevOps-Setup.md)** - Azure DevOps configuration
- **[Lab-16-CICD-Pipeline.md](./Lab-16-CICD-Pipeline.md)** - Build and release pipelines
- **[Lab-17-Deployment-Strategies.md](./Lab-17-Deployment-Strategies.md)** - Blue-Green, Canary, Rolling

### Security Labs
- **[Lab-18-Azure-AD.md](./Lab-18-Azure-AD.md)** - Identity and access management
- **[Lab-19-Key-Vault.md](./Lab-19-Key-Vault.md)** - Secrets management
- **[Lab-20-Network-Security.md](./Lab-20-Network-Security.md)** - Firewall, NSG, DDoS

### Monitoring Labs
- **[Lab-21-Azure-Monitor.md](./Lab-21-Azure-Monitor.md)** - Monitoring and diagnostics
- **[Lab-22-Log-Analytics.md](./Lab-22-Log-Analytics.md)** - Log queries and analysis
- **[Lab-23-Application-Insights.md](./Lab-23-Application-Insights.md)** - Application performance monitoring

### Complete Scenarios
- **[Lab-24-Three-Tier-App.md](./Lab-24-Three-Tier-App.md)** - Deploy complete 3-tier application
- **[Lab-25-Microservices-Architecture.md](./Lab-25-Microservices-Architecture.md)** - Microservices on AKS
- **[Lab-26-Disaster-Recovery.md](./Lab-26-Disaster-Recovery.md)** - Backup and DR implementation

## 🚀 Getting Started

### Prerequisites
- Active Azure subscription
- Azure CLI installed
- Basic understanding of cloud concepts
- Text editor or IDE

### Setup Instructions

1. **Install Azure CLI**
```bash
# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew install azure-cli

# Windows
# Download from https://aka.ms/installazurecliwindows
```

2. **Login to Azure**
```bash
az login
az account set --subscription "Your-Subscription-Name"
```

3. **Verify Setup**
```bash
az account show
az group list
```

## 📖 How to Use These Labs

1. **Sequential Learning**: Start with Lab 01 and progress through each lab
2. **Targeted Practice**: Jump to specific labs based on your learning needs
3. **Hands-On**: Execute every command and verify results
4. **Cleanup**: Always run cleanup commands to avoid unnecessary costs

## 💡 Lab Format

Each lab includes:
- ✅ **Prerequisites** - What you need before starting
- ✅ **Objectives** - What you'll learn
- ✅ **Step-by-Step Instructions** - Detailed walkthrough
- ✅ **Portal Method** - GUI-based approach
- ✅ **CLI Method** - Command-line approach
- ✅ **PowerShell Method** - PowerShell scripts (where applicable)
- ✅ **Verification Steps** - How to confirm success
- ✅ **Troubleshooting** - Common issues and solutions
- ✅ **Cleanup** - Resource deletion to avoid costs

## 🎓 Learning Path

### Beginner Track (Weeks 1-2)
1. Lab 01: Virtual Machine
2. Lab 03: Storage Account
3. Lab 11: Virtual Network
4. Lab 08: Azure SQL

### Intermediate Track (Weeks 3-4)
1. Lab 05: Docker Basics
2. Lab 06: AKS Deployment
3. Lab 16: CI/CD Pipeline
4. Lab 14: Azure CDN

### Advanced Track (Weeks 5-6)
1. Lab 07: AKS Advanced
2. Lab 17: Deployment Strategies
3. Lab 24: Three-Tier App
4. Lab 25: Microservices Architecture

## 💰 Cost Management

**Estimated Monthly Costs:**
- Basic Labs (VM, Storage): $50-100
- Container Labs (AKS): $200-300
- Database Labs: $50-150
- Complete Scenarios: $300-500

**Cost Saving Tips:**
- ✅ Use B-series VMs for dev/test
- ✅ Enable auto-shutdown for VMs
- ✅ Delete resources after lab completion
- ✅ Use Azure Free Tier where available
- ✅ Set up budget alerts

## 🔧 Troubleshooting

### Common Issues

**Issue: Insufficient quota**
```bash
# Check quota
az vm list-usage --location eastus --output table

# Request quota increase via Portal
```

**Issue: Authentication failed**
```bash
# Re-login
az logout
az login
az account set --subscription "Your-Subscription-Name"
```

**Issue: Resource already exists**
```bash
# Use unique names with timestamps
TIMESTAMP=$(date +%Y%m%d%H%M)
RESOURCE_NAME="myresource-${TIMESTAMP}"
```

## 📞 Support

- **Azure Documentation**: https://docs.microsoft.com/azure
- **Azure CLI Reference**: https://docs.microsoft.com/cli/azure
- **Community Forums**: https://docs.microsoft.com/answers/products/azure

## 🎯 Certification Alignment

These labs align with:
- **AZ-305**: Azure Solutions Architect Expert
- **AZ-104**: Azure Administrator Associate
- **AZ-400**: DevOps Engineer Expert

## ✅ Lab Completion Checklist

Track your progress:

### Compute
- [ ] Lab 01: Virtual Machine
- [ ] Lab 02: App Service

### Storage
- [ ] Lab 03: Storage Account
- [ ] Lab 04: Azure Files

### Containers
- [ ] Lab 05: Docker Basics
- [ ] Lab 06: AKS Deployment
- [ ] Lab 07: AKS Advanced

### Databases
- [ ] Lab 08: Azure SQL
- [ ] Lab 09: MySQL Database
- [ ] Lab 10: Cosmos DB

### Networking
- [ ] Lab 11: Virtual Network
- [ ] Lab 12: Load Balancer
- [ ] Lab 13: Application Gateway
- [ ] Lab 14: Azure CDN

### DevOps
- [ ] Lab 15: Azure DevOps Setup
- [ ] Lab 16: CI/CD Pipeline
- [ ] Lab 17: Deployment Strategies

### Security
- [ ] Lab 18: Azure AD
- [ ] Lab 19: Key Vault
- [ ] Lab 20: Network Security

### Monitoring
- [ ] Lab 21: Azure Monitor
- [ ] Lab 22: Log Analytics
- [ ] Lab 23: Application Insights

### Complete Scenarios
- [ ] Lab 24: Three-Tier App
- [ ] Lab 25: Microservices Architecture
- [ ] Lab 26: Disaster Recovery

---

**Happy Learning! 🚀**

**© Copyright Sivakumar J**
