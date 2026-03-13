# Domain 1: Design Identity, Governance, and Monitoring Solutions (25-30%)

## 1.1 Design Authentication and Authorization Solutions

### Azure Active Directory (Azure AD / Entra ID)

**Key Concepts:**
- **Authentication:** Verifying identity (who you are)
- **Authorization:** Determining access rights (what you can do)

**Azure AD Features:**
- Single Sign-On (SSO)
- Multi-Factor Authentication (MFA)
- Conditional Access
- Identity Protection
- Privileged Identity Management (PIM)

### Authentication Methods

**1. Passwordless Authentication**
- Windows Hello for Business
- FIDO2 security keys
- Microsoft Authenticator app

**2. Multi-Factor Authentication (MFA)**
- Something you know (password)
- Something you have (phone, token)
- Something you are (biometrics)

### Conditional Access

**Components:**
- **Signals:** User, location, device, application, risk
- **Decisions:** Allow, block, require MFA
- **Enforcement:** Apply policies

### Managed Identities

**System-Assigned:**
- Tied to Azure resource lifecycle
- One-to-one relationship

**User-Assigned:**
- Standalone Azure resource
- Can be assigned to multiple resources

## 1.2 Design Governance Solutions

### Azure Policy

**Effects:**
- Deny, Audit, Append, Modify, DeployIfNotExists, AuditIfNotExists

### Azure RBAC

**Built-in Roles:**
- Owner, Contributor, Reader, User Access Administrator

## 1.3 Design Monitoring and Logging Solutions

### Azure Monitor Components
- Metrics, Logs, Alerts, Workbooks, Insights

### Log Analytics (KQL Examples)

```kql
SigninLogs
| where ResultType != 0
| summarize count() by UserPrincipalName
```

## Key Takeaways

✅ Use Conditional Access for zero-trust security  
✅ Implement MFA for all privileged accounts  
✅ Use Managed Identities instead of storing credentials  
✅ Apply Azure Policy for governance at scale  
✅ Enable diagnostic settings for all critical resources

---

**© Copyright Sivakumar J**
