# Lab 19: Key Vault

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure CLI
- Application requiring secrets

## Objective
Configure Azure Key Vault for secrets, keys, and certificates management.

---

## Create Key Vault

```bash
# Create resource group
az group create --name rg-keyvault-lab --location eastus

# Create Key Vault
az keyvault create \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab \
  --location eastus \
  --sku standard \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true

# Set access policy
az keyvault set-policy \
  --name kv-lab-unique-123 \
  --upn user@example.com \
  --secret-permissions get list set delete \
  --key-permissions get list create delete \
  --certificate-permissions get list create delete
```

---

## Manage Secrets

```bash
# Create secret
az keyvault secret set \
  --vault-name kv-lab-unique-123 \
  --name "DatabasePassword" \
  --value "MySecretP@ssw0rd"

# Get secret
az keyvault secret show \
  --vault-name kv-lab-unique-123 \
  --name "DatabasePassword" \
  --query value -o tsv

# List secrets
az keyvault secret list \
  --vault-name kv-lab-unique-123 \
  --output table

# Update secret
az keyvault secret set \
  --vault-name kv-lab-unique-123 \
  --name "DatabasePassword" \
  --value "NewSecretP@ssw0rd"

# Delete secret
az keyvault secret delete \
  --vault-name kv-lab-unique-123 \
  --name "DatabasePassword"

# Recover deleted secret
az keyvault secret recover \
  --vault-name kv-lab-unique-123 \
  --name "DatabasePassword"
```

---

## Manage Keys

```bash
# Create key
az keyvault key create \
  --vault-name kv-lab-unique-123 \
  --name "EncryptionKey" \
  --kty RSA \
  --size 2048

# List keys
az keyvault key list \
  --vault-name kv-lab-unique-123 \
  --output table

# Encrypt data
az keyvault key encrypt \
  --vault-name kv-lab-unique-123 \
  --name "EncryptionKey" \
  --algorithm RSA-OAEP \
  --value "SGVsbG8gV29ybGQ="

# Decrypt data
az keyvault key decrypt \
  --vault-name kv-lab-unique-123 \
  --name "EncryptionKey" \
  --algorithm RSA-OAEP \
  --value "<ENCRYPTED_VALUE>"

# Rotate key
az keyvault key rotate \
  --vault-name kv-lab-unique-123 \
  --name "EncryptionKey"
```

---

## Manage Certificates

```bash
# Create self-signed certificate
az keyvault certificate create \
  --vault-name kv-lab-unique-123 \
  --name "MyCertificate" \
  --policy '{
    "issuerParameters": {"name": "Self"},
    "keyProperties": {"exportable": true, "keySize": 2048, "keyType": "RSA"},
    "x509CertificateProperties": {
      "subject": "CN=example.com",
      "validityInMonths": 12
    }
  }'

# Import certificate
az keyvault certificate import \
  --vault-name kv-lab-unique-123 \
  --name "ImportedCert" \
  --file certificate.pfx \
  --password "certpassword"

# Download certificate
az keyvault certificate download \
  --vault-name kv-lab-unique-123 \
  --name "MyCertificate" \
  --file certificate.pem

# List certificates
az keyvault certificate list \
  --vault-name kv-lab-unique-123 \
  --output table
```

---

## Configure Managed Identity Access

```bash
# Create VM with managed identity
az vm create \
  --resource-group rg-keyvault-lab \
  --name vm-app \
  --image Ubuntu2204 \
  --assign-identity \
  --generate-ssh-keys

# Get managed identity
IDENTITY=$(az vm show \
  --resource-group rg-keyvault-lab \
  --name vm-app \
  --query identity.principalId -o tsv)

# Grant access to Key Vault
az keyvault set-policy \
  --name kv-lab-unique-123 \
  --object-id $IDENTITY \
  --secret-permissions get list
```

**Access from application (Python)**
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://kv-lab-unique-123.vault.azure.net/", credential=credential)

# Get secret
secret = client.get_secret("DatabasePassword")
print(secret.value)
```

---

## Configure Soft Delete and Purge Protection

```bash
# Enable soft delete (enabled by default)
az keyvault update \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab \
  --enable-soft-delete true \
  --retention-days 90

# Enable purge protection
az keyvault update \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab \
  --enable-purge-protection true

# List deleted vaults
az keyvault list-deleted --output table

# Recover deleted vault
az keyvault recover \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab
```

---

## Configure Network Security

```bash
# Enable firewall
az keyvault update \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab \
  --default-action Deny

# Add IP rule
az keyvault network-rule add \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab \
  --ip-address <YOUR_IP>

# Add VNet rule
az keyvault network-rule add \
  --name kv-lab-unique-123 \
  --resource-group rg-keyvault-lab \
  --vnet-name vnet-app \
  --subnet subnet-app

# Create private endpoint
az network private-endpoint create \
  --resource-group rg-keyvault-lab \
  --name pe-keyvault \
  --vnet-name vnet-app \
  --subnet subnet-app \
  --private-connection-resource-id <KEYVAULT_ID> \
  --group-id vault \
  --connection-name keyvault-connection
```

---

## Configure Logging

```bash
# Enable diagnostic settings
az monitor diagnostic-settings create \
  --name keyvault-diagnostics \
  --resource <KEYVAULT_ID> \
  --logs '[{"category": "AuditEvent", "enabled": true}]' \
  --workspace <LOG_ANALYTICS_WORKSPACE_ID>
```

---

## Key Takeaways
- Key Vault secures secrets, keys, and certificates
- Managed identities eliminate hardcoded credentials
- Soft delete protects against accidental deletion
- Purge protection prevents permanent deletion
- Network rules restrict access
- Private endpoints provide private connectivity
- Audit logs track all access
