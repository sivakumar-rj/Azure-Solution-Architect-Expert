# Lab 17: Deployment Strategies

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure App Service or AKS
- CI/CD pipeline configured
- Application with multiple versions

## Objective
Implement blue-green, canary, and rolling deployment strategies.

---

## Blue-Green Deployment (App Service)

```bash
# Create production slot
az webapp create \
  --resource-group rg-deploy-lab \
  --plan plan-webapp \
  --name myapp-prod \
  --runtime "NODE:20-lts"

# Create staging slot (green)
az webapp deployment slot create \
  --resource-group rg-deploy-lab \
  --name myapp-prod \
  --slot staging

# Deploy to staging
az webapp deployment source config-zip \
  --resource-group rg-deploy-lab \
  --name myapp-prod \
  --slot staging \
  --src app-v2.zip

# Test staging
curl https://myapp-prod-staging.azurewebsites.net

# Swap slots (blue-green switch)
az webapp deployment slot swap \
  --resource-group rg-deploy-lab \
  --name myapp-prod \
  --slot staging \
  --target-slot production

# Rollback if needed
az webapp deployment slot swap \
  --resource-group rg-deploy-lab \
  --name myapp-prod \
  --slot production \
  --target-slot staging
```

---

## Canary Deployment (Traffic Manager)

```bash
# Create Traffic Manager profile
az network traffic-manager profile create \
  --resource-group rg-deploy-lab \
  --name tm-canary \
  --routing-method Weighted \
  --unique-dns-name myapp-canary

# Add production endpoint (90% traffic)
az network traffic-manager endpoint create \
  --resource-group rg-deploy-lab \
  --profile-name tm-canary \
  --name prod-endpoint \
  --type azureEndpoints \
  --target-resource-id <PROD_APP_ID> \
  --weight 90

# Add canary endpoint (10% traffic)
az network traffic-manager endpoint create \
  --resource-group rg-deploy-lab \
  --profile-name tm-canary \
  --name canary-endpoint \
  --type azureEndpoints \
  --target-resource-id <CANARY_APP_ID> \
  --weight 10

# Gradually increase canary traffic
az network traffic-manager endpoint update \
  --resource-group rg-deploy-lab \
  --profile-name tm-canary \
  --name canary-endpoint \
  --weight 50

# Full rollout
az network traffic-manager endpoint update \
  --resource-group rg-deploy-lab \
  --profile-name tm-canary \
  --name canary-endpoint \
  --weight 100
```

---

## Rolling Deployment (AKS)

**deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: myapp
        image: myapp:v2
        ports:
        - containerPort: 3000
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 15
          periodSeconds: 10
```

```bash
# Apply rolling update
kubectl apply -f deployment.yaml

# Watch rollout
kubectl rollout status deployment/myapp

# Pause rollout
kubectl rollout pause deployment/myapp

# Resume rollout
kubectl rollout resume deployment/myapp

# Rollback
kubectl rollout undo deployment/myapp
```

---

## Canary Deployment (AKS with Istio)

**canary-deployment.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v1
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
      labels:
        app: myapp
        version: v1
    spec:
      containers:
      - name: myapp
        image: myapp:v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: v2
  template:
    metadata:
      labels:
        app: myapp
        version: v2
    spec:
      containers:
      - name: myapp
        image: myapp:v2
```

**virtual-service.yaml** (Istio)
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: myapp
        subset: v2
  - route:
    - destination:
        host: myapp
        subset: v1
      weight: 90
    - destination:
        host: myapp
        subset: v2
      weight: 10
```

---

## Feature Flags

**Using Azure App Configuration**
```bash
# Create App Configuration
az appconfig create \
  --resource-group rg-deploy-lab \
  --name appconfig-features \
  --location eastus \
  --sku Standard

# Add feature flag
az appconfig feature set \
  --name NewFeature \
  --config-store-name appconfig-features \
  --enabled true \
  --label production

# Enable for percentage
az appconfig feature filter add \
  --name NewFeature \
  --config-store-name appconfig-features \
  --filter-name Microsoft.Percentage \
  --filter-parameters '{"Value": 25}'
```

**Application code (Node.js)**
```javascript
const { AppConfigurationClient } = require("@azure/app-configuration");
const { FeatureManager } = require("@microsoft/feature-management");

const client = new AppConfigurationClient(connectionString);
const featureManager = new FeatureManager(client);

if (await featureManager.isEnabled("NewFeature")) {
  // New feature code
} else {
  // Old feature code
}
```

---

## Key Takeaways
- Blue-green enables instant rollback
- Canary reduces risk with gradual rollout
- Rolling updates minimize downtime
- Feature flags decouple deployment from release
- Traffic splitting controls exposure
- Health probes ensure stability
- Always have rollback plan
