# Lab 25: Microservices Architecture

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- AKS cluster
- Docker knowledge
- Microservices concepts

## Objective
Deploy microservices architecture on AKS with service mesh and API gateway.

---

## Architecture Overview

```
API Gateway (Ingress) → Service Mesh (Istio/Linkerd)
    ↓
User Service → Auth Service
    ↓
Product Service → Inventory Service
    ↓
Order Service → Payment Service
    ↓
Notification Service
```

---

## Create AKS Cluster

```bash
# Create resource group
az group create --name rg-microservices-lab --location eastus

# Create ACR
az acr create \
  --resource-group rg-microservices-lab \
  --name acrmicroservices$RANDOM \
  --sku Basic

# Create AKS with service mesh
az aks create \
  --resource-group rg-microservices-lab \
  --name aks-microservices \
  --node-count 3 \
  --enable-managed-identity \
  --attach-acr acrmicroservices$RANDOM \
  --network-plugin azure \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials \
  --resource-group rg-microservices-lab \
  --name aks-microservices
```

---

## Create Microservices

**User Service (user-service/app.js):**
```javascript
const express = require('express');
const app = express();
app.use(express.json());

const users = [];

app.get('/api/users', (req, res) => {
    res.json(users);
});

app.post('/api/users', (req, res) => {
    const user = {id: Date.now(), ...req.body};
    users.push(user);
    res.status(201).json(user);
});

app.listen(3000, () => console.log('User service running on port 3000'));
```

**Product Service (product-service/app.js):**
```javascript
const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const products = [];

app.get('/api/products', async (req, res) => {
    // Call inventory service
    const inventory = await axios.get('http://inventory-service:3000/api/inventory');
    const productsWithStock = products.map(p => ({
        ...p,
        stock: inventory.data.find(i => i.productId === p.id)?.quantity || 0
    }));
    res.json(productsWithStock);
});

app.post('/api/products', (req, res) => {
    const product = {id: Date.now(), ...req.body};
    products.push(product);
    res.status(201).json(product);
});

app.listen(3000, () => console.log('Product service running on port 3000'));
```

**Order Service (order-service/app.js):**
```javascript
const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const orders = [];

app.post('/api/orders', async (req, res) => {
    try {
        // Verify product
        const product = await axios.get(`http://product-service:3000/api/products/${req.body.productId}`);
        
        // Process payment
        const payment = await axios.post('http://payment-service:3000/api/payments', {
            amount: product.data.price * req.body.quantity
        });
        
        // Create order
        const order = {
            id: Date.now(),
            ...req.body,
            paymentId: payment.data.id,
            status: 'confirmed'
        };
        orders.push(order);
        
        // Send notification
        await axios.post('http://notification-service:3000/api/notifications', {
            type: 'order_confirmed',
            orderId: order.id
        });
        
        res.status(201).json(order);
    } catch (error) {
        res.status(500).json({error: error.message});
    }
});

app.listen(3000, () => console.log('Order service running on port 3000'));
```

---

## Build and Push Images

```bash
# Login to ACR
az acr login --name acrmicroservices$RANDOM

# Build and push images
for service in user-service product-service inventory-service order-service payment-service notification-service; do
    docker build -t acrmicroservices$RANDOM.azurecr.io/$service:v1 ./$service
    docker push acrmicroservices$RANDOM.azurecr.io/$service:v1
done
```

---

## Deploy to Kubernetes

**user-service.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1
    spec:
      containers:
      - name: user-service
        image: acrmicroservices.azurecr.io/user-service:v1
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

```bash
# Deploy all services
kubectl apply -f user-service.yaml
kubectl apply -f product-service.yaml
kubectl apply -f inventory-service.yaml
kubectl apply -f order-service.yaml
kubectl apply -f payment-service.yaml
kubectl apply -f notification-service.yaml
```

---

## Install Istio Service Mesh

```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio
istioctl install --set profile=demo -y

# Enable sidecar injection
kubectl label namespace default istio-injection=enabled

# Restart pods to inject sidecars
kubectl rollout restart deployment
```

---

## Configure Traffic Management

**virtual-service.yaml:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: product-service
spec:
  hosts:
  - product-service
  http:
  - match:
    - headers:
        version:
          exact: v2
    route:
    - destination:
        host: product-service
        subset: v2
  - route:
    - destination:
        host: product-service
        subset: v1
      weight: 90
    - destination:
        host: product-service
        subset: v2
      weight: 10
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: product-service
spec:
  host: product-service
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

---

## Configure Circuit Breaker

**destination-rule.yaml:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: payment-service
spec:
  host: payment-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
```

---

## Deploy API Gateway

**ingress.yaml:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 3000
      - path: /products(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 3000
      - path: /orders(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 3000
```

---

## Configure Distributed Tracing

```bash
# Install Jaeger
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml

# Access Jaeger UI
istioctl dashboard jaeger
```

---

## Configure Service Monitoring

```bash
# Install Prometheus and Grafana
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml

# Access Grafana
istioctl dashboard grafana
```

---

## Implement Event-Driven Communication

**Using Azure Service Bus:**
```javascript
const { ServiceBusClient } = require("@azure/service-bus");

const connectionString = process.env.SERVICE_BUS_CONNECTION_STRING;
const client = new ServiceBusClient(connectionString);

// Publisher (Order Service)
async function publishOrderEvent(order) {
    const sender = client.createSender("orders");
    await sender.sendMessages({
        body: order,
        contentType: "application/json"
    });
}

// Subscriber (Notification Service)
async function subscribeToOrders() {
    const receiver = client.createReceiver("orders");
    receiver.subscribe({
        processMessage: async (message) => {
            console.log("Received order:", message.body);
            // Send notification
        },
        processError: async (error) => {
            console.error(error);
        }
    });
}
```

---

## Key Takeaways
- Microservices enable independent deployment
- Service mesh provides traffic management
- Circuit breakers prevent cascade failures
- API gateway centralizes entry point
- Distributed tracing tracks requests
- Event-driven communication decouples services
- Container orchestration with Kubernetes
- Observability is critical
