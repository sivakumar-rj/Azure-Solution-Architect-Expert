# Azure Security and Identity - Deep Dive

## Azure Active Directory (Entra ID) - Complete Guide

### Identity Types

**User Identities:**
- Cloud-only users (created in Azure AD)
- Synchronized users (from on-premises AD)
- Guest users (B2B collaboration)
- External identities (B2C consumers)

**Non-Human Identities:**
- Service Principals
- Managed Identities (System-assigned, User-assigned)
- Application registrations

### Authentication Methods Comparison

| Method | Security Level | User Experience | Cost |
|--------|---------------|-----------------|------|
| Password only | Low | Easy | Free |
| Password + SMS | Medium | Moderate | Free |
| Password + Authenticator | High | Good | Free |
| Passwordless (FIDO2) | Very High | Excellent | Hardware cost |
| Certificate-based | Very High | Seamless | PKI cost |
| Windows Hello | Very High | Excellent | Free (Windows 10+) |

### Conditional Access Policies - Real Examples

**Policy 1: Require MFA for Admins**
```
Name: Require-MFA-For-Admins
Assignments:
  Users: All admin roles
  Cloud apps: All cloud apps
Conditions:
  Locations: Any location
Access controls:
  Grant: Require MFA
Session: Sign-in frequency: 8 hours
State: Enabled
```

**Policy 2: Block Legacy Authentication**
```
Name: Block-Legacy-Auth
Assignments:
  Users: All users
  Cloud apps: All cloud apps
Conditions:
  Client apps: Exchange ActiveSync, Other clients
Access controls:
  Block access
State: Report-only (test first)
```

**Policy 3: Require Compliant Device**
```
Name: Require-Compliant-Device-Corporate-Data
Assignments:
  Users: All users
  Cloud apps: Office 365, SharePoint
Conditions:
  Locations: Any location
  Device platforms: All
Access controls:
  Grant: Require device to be marked as compliant
  OR Require Hybrid Azure AD joined device
State: Enabled
```

**Policy 4: Risk-Based Access**
```
Name: Block-High-Risk-Sign-Ins
Assignments:
  Users: All users
  Cloud apps: All cloud apps
Conditions:
  Sign-in risk: High
Access controls:
  Block access
State: Enabled
```

### Privileged Identity Management (PIM)

**Role Activation Settings:**
```
Role: Global Administrator
Maximum activation duration: 8 hours
Require MFA on activation: Yes
Require justification: Yes
Require approval: Yes
Approvers: Security team
Notification: Send email to approvers
```

**Eligible vs Permanent Assignments:**
- **Eligible:** User must activate role when needed (recommended)
- **Permanent:** Always active (use sparingly)

**PIM Workflow:**
1. User requests role activation
2. Provides business justification
3. Completes MFA
4. Approver reviews and approves
5. Role active for specified duration
6. Automatic deactivation after time expires

### Azure AD B2B (Business-to-Business)

**Use Cases:**
- Partner collaboration
- Vendor access
- Consultant access
- Cross-organization projects

**Configuration:**
```
External collaboration settings:
  Guest user access: Limited access
  Guest invite settings: Only admins can invite
  Collaboration restrictions: Allow invitations to any domain
  Cross-tenant access: Configure per-partner
```

**Guest User Lifecycle:**
1. Admin sends invitation
2. Guest receives email
3. Guest accepts (uses own credentials)
4. Guest accesses resources
5. Access reviewed quarterly
6. Remove inactive guests

### Azure AD B2C (Business-to-Consumer)

**Use Cases:**
- Customer-facing applications
- E-commerce platforms
- Mobile apps
- SaaS applications

**Identity Providers:**
- Local accounts (email/username)
- Social: Google, Facebook, Microsoft, LinkedIn
- Enterprise: SAML, OpenID Connect
- Custom: Any OAuth 2.0 provider

**User Flows:**
```
Sign-up and sign-in flow:
  - Email verification
  - Password requirements
  - MFA (optional)
  - Custom attributes (age, preferences)
  - Terms of service acceptance
  
Password reset flow:
  - Email verification
  - Security questions
  - New password requirements
  
Profile editing flow:
  - Update personal information
  - Change password
  - Manage MFA
```

## Azure Security Services

### Microsoft Defender for Cloud

**Security Posture Management:**
- Secure Score (0-100%)
- Recommendations by severity
- Compliance dashboard
- Resource hygiene

**Workload Protection:**
- Defender for Servers
- Defender for App Service
- Defender for Storage
- Defender for SQL
- Defender for Kubernetes
- Defender for Container Registries
- Defender for Key Vault
- Defender for DNS
- Defender for Resource Manager

**Pricing Example:**
```
Environment: 100 VMs, 50 App Services, 20 SQL Databases
- Defender for Servers: 100 × $15 = $1,500/month
- Defender for App Service: 50 × $15 = $750/month
- Defender for SQL: 20 × $15 = $300/month
Total: $2,550/month
```

### Azure Key Vault - Advanced Configuration

**Access Policies vs RBAC:**

**Access Policies (Legacy):**
```
User: admin@contoso.com
Key permissions: Get, List, Create, Delete
Secret permissions: Get, List, Set, Delete
Certificate permissions: Get, List, Create
```

**RBAC (Recommended):**
```
Role: Key Vault Secrets User
Assignee: App Service Managed Identity
Scope: Key Vault
```

**Key Vault Networking:**
```
Firewall settings:
  Allow access from: Selected networks
  Virtual networks: Add production VNet
  IP addresses: Add corporate IPs
  Allow trusted Microsoft services: Yes
  
Private endpoint:
  VNet: Production VNet
  Subnet: Private-endpoints-subnet
  Private DNS integration: Yes
```

**Key Rotation:**
```
Automated rotation:
  - Storage account keys: 90 days
  - SQL connection strings: 90 days
  - API keys: 180 days
  
Manual rotation:
  - Certificates: Before expiry
  - Encryption keys: Annually
```

### Azure Sentinel (SIEM)

**Data Connectors:**
- Azure Activity Logs
- Azure AD Sign-in Logs
- Office 365
- Microsoft 365 Defender
- Azure Firewall
- NSG Flow Logs
- Third-party (Palo Alto, Cisco, etc.)

**Analytics Rules:**
```
Rule: Multiple Failed Sign-ins
Type: Scheduled
Query:
  SigninLogs
  | where ResultType != 0
  | summarize FailedAttempts = count() by UserPrincipalName, IPAddress
  | where FailedAttempts > 5
Frequency: Every 5 minutes
Alert threshold: 1
Severity: Medium
Tactics: Credential Access
```

**Playbooks (Automation):**
```
Trigger: Alert created
Actions:
  1. Get user details from Azure AD
  2. Check if user is admin
  3. If admin: Disable account
  4. Send email to security team
  5. Create ServiceNow ticket
  6. Post to Teams channel
```

## Network Security

### Azure Firewall - Advanced Rules

**Application Rule Collection:**
```
Priority: 100
Action: Allow
Rules:
  - Name: Allow-Windows-Update
    Source: 10.0.0.0/16
    Protocol: https:443
    Target FQDNs:
      - *.windowsupdate.microsoft.com
      - *.update.microsoft.com
      - *.windowsupdate.com
      
  - Name: Allow-GitHub
    Source: 10.0.20.0/24 (Dev subnet)
    Protocol: https:443
    Target FQDNs:
      - github.com
      - *.github.com
      - raw.githubusercontent.com
      
  - Name: Allow-Docker-Hub
    Source: 10.0.20.0/24
    Protocol: https:443
    Target FQDNs:
      - *.docker.io
      - *.docker.com
      - registry-1.docker.io
```

**Network Rule Collection:**
```
Priority: 200
Action: Allow
Rules:
  - Name: Allow-DNS
    Source: 10.0.0.0/16
    Destination: *
    Protocol: UDP
    Ports: 53
    
  - Name: Allow-NTP
    Source: 10.0.0.0/16
    Destination: *
    Protocol: UDP
    Ports: 123
    
  - Name: Allow-SQL
    Source: 10.0.20.0/24 (App tier)
    Destination: 10.0.30.0/24 (Data tier)
    Protocol: TCP
    Ports: 1433
```

**Threat Intelligence:**
```
Mode: Alert and deny
Feed: Microsoft threat intelligence
Custom indicators:
  - Known malicious IPs
  - C2 server domains
  - Ransomware IPs
```

### Web Application Firewall (WAF)

**OWASP Top 10 Protection:**
1. SQL Injection
2. Broken Authentication
3. Sensitive Data Exposure
4. XML External Entities (XXE)
5. Broken Access Control
6. Security Misconfiguration
7. Cross-Site Scripting (XSS)
8. Insecure Deserialization
9. Using Components with Known Vulnerabilities
10. Insufficient Logging & Monitoring

**Custom WAF Rules:**
```json
{
  "name": "BlockSQLInjection",
  "priority": 10,
  "ruleType": "MatchRule",
  "matchConditions": [
    {
      "matchVariables": [
        {"variableName": "RequestUri"},
        {"variableName": "QueryString"},
        {"variableName": "PostArgs"}
      ],
      "operator": "Contains",
      "matchValues": [
        "union select",
        "drop table",
        "exec(",
        "execute(",
        "insert into",
        "update set",
        "delete from",
        "' or '1'='1",
        "' or 1=1--",
        "admin'--"
      ],
      "transforms": ["Lowercase", "UrlDecode"]
    }
  ],
  "action": "Block"
}
```

### DDoS Protection

**Standard vs Basic:**

| Feature | Basic | Standard |
|---------|-------|----------|
| Cost | Free | $2,944/month |
| Always-on monitoring | Yes | Yes |
| Adaptive tuning | No | Yes |
| Attack analytics | No | Yes |
| Attack metrics | No | Yes |
| DDoS rapid response | No | Yes |
| Cost protection | No | Yes |
| WAF discount | No | Yes |

**DDoS Protection Plan:**
```
Protected resources:
  - Public IPs: 100
  - Application Gateways: 10
  - Azure Firewall: 5
  
Mitigation policies:
  - TCP SYN flood
  - UDP flood
  - ICMP flood
  - HTTP flood
  - DNS amplification
  
Alerts:
  - Email: security@contoso.com
  - SMS: +1-555-0100
  - Webhook: https://alerts.contoso.com
```

## Data Protection

### Encryption at Rest

**Storage Account Encryption:**
```
Encryption type: Microsoft-managed keys (default)
OR Customer-managed keys (CMK):
  - Key Vault: production-kv
  - Key: storage-encryption-key
  - Auto-rotation: Enabled
  
Infrastructure encryption: Enabled (double encryption)
```

**SQL Database Encryption:**
```
Transparent Data Encryption (TDE):
  - Enabled by default
  - Encryption algorithm: AES-256
  - Key management: Service-managed OR Customer-managed
  
Always Encrypted:
  - Column-level encryption
  - Client-side encryption
  - Keys never exposed to database
```

### Encryption in Transit

**TLS Configuration:**
```
Minimum TLS version: 1.2
Cipher suites:
  - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
  - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
  - TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
  
Disable:
  - SSL 3.0
  - TLS 1.0
  - TLS 1.1
  - Weak ciphers
```

## Compliance and Governance

### Azure Policy - Advanced Examples

**Enforce Tagging:**
```json
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "field": "tags['CostCenter']",
      "exists": "false"
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

**Require Encryption:**
```json
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Storage/storageAccounts"
        },
        {
          "field": "Microsoft.Storage/storageAccounts/encryption.services.blob.enabled",
          "notEquals": "true"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

**Auto-Remediation:**
```json
{
  "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/...",
  "parameters": {},
  "policyEffect": "DeployIfNotExists",
  "remediationTask": {
    "enabled": true,
    "resourceDiscoveryMode": "ExistingNonCompliant"
  }
}
```

## Security Best Practices Checklist

### Identity Security
- [ ] Enable MFA for all users
- [ ] Implement Conditional Access policies
- [ ] Use PIM for privileged roles
- [ ] Disable legacy authentication
- [ ] Enable Azure AD Identity Protection
- [ ] Implement password protection
- [ ] Use managed identities for applications
- [ ] Regular access reviews

### Network Security
- [ ] Implement hub-spoke topology
- [ ] Deploy Azure Firewall
- [ ] Enable NSG flow logs
- [ ] Use private endpoints
- [ ] Implement WAF on Application Gateway
- [ ] Enable DDoS Protection Standard
- [ ] Segment networks with NSGs
- [ ] Use Azure Bastion for VM access

### Data Security
- [ ] Enable encryption at rest
- [ ] Enforce TLS 1.2 minimum
- [ ] Use customer-managed keys
- [ ] Implement data classification
- [ ] Enable soft delete on storage
- [ ] Configure backup retention
- [ ] Implement data loss prevention
- [ ] Regular backup testing

### Monitoring & Compliance
- [ ] Enable Azure Monitor
- [ ] Configure diagnostic settings
- [ ] Implement Azure Sentinel
- [ ] Set up security alerts
- [ ] Enable Microsoft Defender for Cloud
- [ ] Implement Azure Policy
- [ ] Regular compliance audits
- [ ] Security incident response plan

---

**© Copyright Sivakumar J - All Rights Reserved**
