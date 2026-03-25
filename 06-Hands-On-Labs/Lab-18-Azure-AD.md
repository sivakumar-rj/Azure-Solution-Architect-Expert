# Lab 18: Azure AD

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription with Azure AD
- Global Administrator or User Administrator role

## Objective
Configure Azure Active Directory with users, groups, and application registrations.

---

## Create Users

```bash
# Create user
az ad user create \
  --display-name "John Doe" \
  --user-principal-name john@yourdomain.onmicrosoft.com \
  --password "P@ssw0rd123!" \
  --force-change-password-next-sign-in true

# Create bulk users
az ad user create --display-name "Jane Smith" --user-principal-name jane@yourdomain.onmicrosoft.com --password "P@ssw0rd123!"
az ad user create --display-name "Bob Johnson" --user-principal-name bob@yourdomain.onmicrosoft.com --password "P@ssw0rd123!"

# List users
az ad user list --output table

# Update user
az ad user update \
  --id john@yourdomain.onmicrosoft.com \
  --set jobTitle="Developer"

# Delete user
az ad user delete --id john@yourdomain.onmicrosoft.com
```

---

## Create Groups

```bash
# Create security group
az ad group create \
  --display-name "Developers" \
  --mail-nickname developers \
  --description "Development team"

# Add members
az ad group member add \
  --group Developers \
  --member-id <USER_OBJECT_ID>

# List group members
az ad group member list \
  --group Developers \
  --output table

# Create dynamic group (Portal only)
# Go to Azure AD → Groups → New group
# Membership type: Dynamic User
# Dynamic query: user.department -eq "Engineering"
```

---

## Register Application

```bash
# Register app
az ad app create \
  --display-name "MyWebApp" \
  --sign-in-audience AzureADMyOrg \
  --web-redirect-uris https://myapp.com/auth/callback

# Get app ID
APP_ID=$(az ad app list --display-name "MyWebApp" --query [0].appId -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Create client secret
az ad app credential reset \
  --id $APP_ID \
  --append \
  --display-name "MyAppSecret"

# Add API permissions
az ad app permission add \
  --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope

# Grant admin consent
az ad app permission admin-consent --id $APP_ID
```

---

## Configure SSO

**SAML-based SSO (Portal)**
1. Go to Azure AD → Enterprise applications
2. Click "New application"
3. Select application from gallery
4. Configure SAML settings
5. Assign users/groups

**OAuth/OpenID Connect**
```javascript
// Node.js example
const passport = require('passport');
const OIDCStrategy = require('passport-azure-ad').OIDCStrategy;

passport.use(new OIDCStrategy({
    identityMetadata: 'https://login.microsoftonline.com/<TENANT_ID>/v2.0/.well-known/openid-configuration',
    clientID: '<APP_ID>',
    clientSecret: '<CLIENT_SECRET>',
    responseType: 'code id_token',
    responseMode: 'form_post',
    redirectUrl: 'https://myapp.com/auth/callback',
    scope: ['profile', 'email', 'openid']
  },
  function(profile, done) {
    return done(null, profile);
  }
));
```

---

## Configure Conditional Access

```bash
# Create conditional access policy (Portal)
# Go to Azure AD → Security → Conditional Access
# 1. Create new policy
# 2. Assignments:
#    - Users: Select users/groups
#    - Cloud apps: Select apps
#    - Conditions: Locations, devices, risk
# 3. Access controls:
#    - Grant: Require MFA, compliant device
#    - Session: Sign-in frequency
```

---

## Configure MFA

```bash
# Enable MFA per user (Portal)
# Go to Azure AD → Users → Multi-Factor Authentication

# Configure MFA settings
# Go to Azure AD → Security → MFA → Additional cloud-based MFA settings
```

---

## Configure RBAC

```bash
# Assign role to user
az role assignment create \
  --assignee john@yourdomain.onmicrosoft.com \
  --role "Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-prod

# Assign role to group
az role assignment create \
  --assignee <GROUP_OBJECT_ID> \
  --role "Reader" \
  --scope /subscriptions/<SUBSCRIPTION_ID>

# Create custom role
az role definition create --role-definition '{
  "Name": "Virtual Machine Operator",
  "Description": "Can start and stop VMs",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/powerOff/action",
    "Microsoft.Compute/virtualMachines/read"
  ],
  "AssignableScopes": ["/subscriptions/<SUBSCRIPTION_ID>"]
}'
```

---

## Configure B2B

```bash
# Invite external user
az ad user create \
  --display-name "External User" \
  --user-principal-name external@partner.com \
  --user-type Guest

# Configure external collaboration settings (Portal)
# Go to Azure AD → External Identities → External collaboration settings
```

---

## Key Takeaways
- Azure AD is identity and access management service
- Users and groups organize identities
- App registrations enable authentication
- Conditional Access enforces security policies
- MFA adds extra security layer
- RBAC controls Azure resource access
- B2B enables external collaboration
