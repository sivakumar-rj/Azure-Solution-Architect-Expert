# Container Scenarios & Real-World Implementations

## Scenario 1: Microservices E-Commerce Platform

### Architecture
```
Azure Front Door
    ↓
Application Gateway (WAF)
    ↓
AKS Cluster
├── Product Service (ACR: product-service:v1)
├── Order Service (ACR: order-service:v1)
├── Payment Service (ACR: payment-service:v1)
├── Inventory Service (ACR: inventory-service:v1)
└── Notification Service (ACR: notification-service:v1)
    ↓
├── Azure SQL Database
├── Cosmos DB
├── Azure Service Bus
└── Azure Cache for Redis
```

### Implementation

**Product Service Dockerfile**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine
RUN apk add --no-cache dumb-init
WORKDIR /app
RUN addgroup -g 1001 nodejs && adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
USER nodejs
EXPOSE 3000
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

**Docker Compose for Local Development**
```yaml
version: '3.8'

services:
  product-service:
    build: ./product-service
    ports:
      - "3001:3000"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
      - SERVICE_BUS_CONNECTION=${SERVICE_BUS_CONNECTION}
    depends_on:
      - postgres
      - redis

  order-service:
    build: ./order-service
    ports:
      - "3002:3000"
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=redis
      - PRODUCT_SERVICE_URL=http://product-service:3000
    depends_on:
      - postgres
      - redis

  payment-service:
    build: ./payment-service
    ports:
      - "3003:3000"
    environment:
      - PAYMENT_GATEWAY_URL=${PAYMENT_GATEWAY_URL}
      - PAYMENT_API_KEY=${PAYMENT_API_KEY}

  inventory-service:
    build: ./inventory-service
    ports:
      - "3004:3000"
    environment:
      - DB_HOST=postgres
      - PRODUCT_SERVICE_URL=http://product-service:3000

  notification-service:
    build: ./notification-service
    environment:
      - SENDGRID_API_KEY=${SENDGRID_API_KEY}
      - SERVICE_BUS_CONNECTION=${SERVICE_BUS_CONNECTION}

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=devpassword
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - product-service
      - order-service
      - payment-service
      - inventory-service

volumes:
  postgres-data:
```

**NGINX Configuration**
```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream product_service {
        server product-service:3000;
    }
    
    upstream order_service {
        server order-service:3000;
    }
    
    upstream payment_service {
        server payment-service:3000;
    }
    
    upstream inventory_service {
        server inventory-service:3000;
    }

    server {
        listen 80;
        
        location /api/products {
            proxy_pass http://product_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /api/orders {
            proxy_pass http://order_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /api/payments {
            proxy_pass http://payment_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /api/inventory {
            proxy_pass http://inventory_service;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

### CI/CD Pipeline (Azure DevOps)
```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - product-service/*

variables:
  acrName: 'myacr'
  imageRepository: 'product-service'
  dockerfilePath: 'product-service/Dockerfile'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  jobs:
  - job: BuildAndPush
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(acrName)
        tags: |
          $(tag)
          latest

    - task: AzureCLI@2
      displayName: Scan image for vulnerabilities
      inputs:
        azureSubscription: 'Azure-Connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az acr task run \
            --registry $(acrName) \
            --name scan-$(imageRepository) \
            --cmd "$(acrName).azurecr.io/$(imageRepository):$(tag)"

- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployToAKS
    environment: 'production'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: Deploy to AKS
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: 'AKS-Connection'
              namespace: 'production'
              manifests: |
                k8s/deployment.yaml
                k8s/service.yaml
              containers: |
                $(acrName).azurecr.io/$(imageRepository):$(tag)
```

---

## Scenario 2: Batch Processing with Containers

### Architecture
```
Azure Storage (Input Blobs)
    ↓
Azure Service Bus Queue
    ↓
ACI Container Groups (Auto-scale)
    ↓
Process Data
    ↓
Azure Storage (Output Blobs)
```

### Batch Processor Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN useradd -m -u 1000 processor && chown -R processor:processor /app
USER processor

CMD ["python", "batch_processor.py"]
```

**Batch Processor Script**
```python
# batch_processor.py
import os
import logging
from azure.storage.blob import BlobServiceClient
from azure.servicebus import ServiceBusClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def process_message(message_body):
    """Process individual message"""
    logger.info(f"Processing: {message_body}")
    # Your processing logic here
    return f"Processed: {message_body}"

def main():
    # Service Bus connection
    sb_connection = os.getenv('SERVICE_BUS_CONNECTION')
    queue_name = os.getenv('QUEUE_NAME')
    
    # Storage connection
    storage_connection = os.getenv('STORAGE_CONNECTION')
    
    with ServiceBusClient.from_connection_string(sb_connection) as client:
        receiver = client.get_queue_receiver(queue_name)
        
        with receiver:
            for msg in receiver:
                try:
                    result = process_message(str(msg))
                    
                    # Upload result to blob storage
                    blob_client = BlobServiceClient.from_connection_string(
                        storage_connection
                    ).get_blob_client("output", f"result-{msg.message_id}.txt")
                    
                    blob_client.upload_blob(result, overwrite=True)
                    
                    receiver.complete_message(msg)
                    logger.info(f"Completed: {msg.message_id}")
                    
                except Exception as e:
                    logger.error(f"Error: {e}")
                    receiver.abandon_message(msg)

if __name__ == "__main__":
    main()
```

**Deploy with Azure CLI**
```bash
# Create container instance
az container create \
  --resource-group batch-rg \
  --name batch-processor-1 \
  --image myacr.azurecr.io/batch-processor:latest \
  --registry-login-server myacr.azurecr.io \
  --registry-username $(az acr credential show --name myacr --query username -o tsv) \
  --registry-password $(az acr credential show --name myacr --query passwords[0].value -o tsv) \
  --environment-variables \
    QUEUE_NAME=batch-queue \
  --secure-environment-variables \
    SERVICE_BUS_CONNECTION="Endpoint=sb://..." \
    STORAGE_CONNECTION="DefaultEndpointsProtocol=https..." \
  --cpu 2 \
  --memory 4 \
  --restart-policy OnFailure
```

---

## Scenario 3: Machine Learning Model Serving

### Architecture
```
Client Request
    ↓
Azure Front Door
    ↓
AKS with GPU Nodes
├── Model Serving Container (TensorFlow Serving)
├── Preprocessing Container
└── Postprocessing Container
    ↓
Azure Blob Storage (Model Files)
```

### TensorFlow Serving Dockerfile
```dockerfile
FROM tensorflow/serving:latest-gpu

# Copy model
COPY models /models

# Environment variables
ENV MODEL_NAME=my_model
ENV MODEL_BASE_PATH=/models

# Expose ports
EXPOSE 8500 8501

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8501/v1/models/${MODEL_NAME} || exit 1

# Start serving
CMD ["tensorflow_model_server", \
     "--rest_api_port=8501", \
     "--model_name=${MODEL_NAME}", \
     "--model_base_path=${MODEL_BASE_PATH}/${MODEL_NAME}"]
```

### Custom ML API Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Download model from Azure Blob
RUN python download_model.py

# Non-root user
RUN useradd -m -u 1000 mluser && chown -R mluser:mluser /app
USER mluser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

**FastAPI Application**
```python
# main.py
from fastapi import FastAPI, File, UploadFile
import tensorflow as tf
import numpy as np
from PIL import Image
import io

app = FastAPI()

# Load model
model = tf.keras.models.load_model('/app/models/my_model')

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Read image
    image_data = await file.read()
    image = Image.open(io.BytesIO(image_data))
    
    # Preprocess
    image = image.resize((224, 224))
    image_array = np.array(image) / 255.0
    image_array = np.expand_dims(image_array, axis=0)
    
    # Predict
    predictions = model.predict(image_array)
    
    return {
        "predictions": predictions.tolist(),
        "class": int(np.argmax(predictions))
    }
```

**Kubernetes Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ml-api
  template:
    metadata:
      labels:
        app: ml-api
    spec:
      nodeSelector:
        accelerator: nvidia-tesla-t4
      containers:
      - name: ml-api
        image: myacr.azurecr.io/ml-api:v1
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
            nvidia.com/gpu: 1
          limits:
            memory: "8Gi"
            cpu: "4"
            nvidia.com/gpu: 1
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: ml-api-service
spec:
  selector:
    app: ml-api
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer
```

---

## Scenario 4: Multi-Stage Build for .NET Microservice

### Optimized Dockerfile
```dockerfile
# Stage 1: Restore dependencies
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS restore
WORKDIR /src
COPY ["MyService/MyService.csproj", "MyService/"]
COPY ["MyService.Domain/MyService.Domain.csproj", "MyService.Domain/"]
COPY ["MyService.Infrastructure/MyService.Infrastructure.csproj", "MyService.Infrastructure/"]
RUN dotnet restore "MyService/MyService.csproj"

# Stage 2: Build
FROM restore AS build
COPY . .
WORKDIR "/src/MyService"
RUN dotnet build "MyService.csproj" -c Release -o /app/build --no-restore

# Stage 3: Publish
FROM build AS publish
RUN dotnet publish "MyService.csproj" -c Release -o /app/publish --no-restore

# Stage 4: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS final
WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser && \
    chown -R appuser:appgroup /app

COPY --from=publish --chown=appuser:appgroup /app/publish .

USER appuser

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "MyService.dll"]
```

### Docker Compose with Health Checks
```yaml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=MyDb;User=sa;Password=YourStrong@Passw0rd;
    depends_on:
      sqlserver:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrong@Passw0rd
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -Q 'SELECT 1'"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

volumes:
  sqlserver-data:
```

---

## Scenario 5: Sidecar Pattern for Logging

### Application with Fluentd Sidecar
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:v1
    volumes:
      - app-logs:/var/log/app
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  fluentd:
    image: fluent/fluentd:v1.16-1
    volumes:
      - app-logs:/var/log/app:ro
      - ./fluentd.conf:/fluentd/etc/fluent.conf
    environment:
      - FLUENT_ELASTICSEARCH_HOST=elasticsearch
      - FLUENT_ELASTICSEARCH_PORT=9200
    depends_on:
      - elasticsearch

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - es-data:/usr/share/elasticsearch/data

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

volumes:
  app-logs:
  es-data:
```

**Fluentd Configuration**
```conf
# fluentd.conf
<source>
  @type tail
  path /var/log/app/*.log
  pos_file /var/log/fluentd/app.log.pos
  tag app.logs
  <parse>
    @type json
    time_key timestamp
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>

<filter app.logs>
  @type record_transformer
  <record>
    hostname "#{Socket.gethostname}"
    environment "#{ENV['ENVIRONMENT']}"
  </record>
</filter>

<match app.logs>
  @type elasticsearch
  host "#{ENV['FLUENT_ELASTICSEARCH_HOST']}"
  port "#{ENV['FLUENT_ELASTICSEARCH_PORT']}"
  logstash_format true
  logstash_prefix app-logs
  include_tag_key true
  tag_key @log_name
  flush_interval 10s
</match>
```

---

## Container Monitoring & Observability

### Prometheus Metrics in Application
```python
# app.py (Python Flask with Prometheus)
from flask import Flask
from prometheus_client import Counter, Histogram, generate_latest
import time

app = Flask(__name__)

# Metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration', ['method', 'endpoint'])

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    duration = time.time() - request.start_time
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_DURATION.labels(request.method, request.path).observe(duration)
    return response

@app.route('/metrics')
def metrics():
    return generate_latest()

@app.route('/health')
def health():
    return {'status': 'healthy'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

### Docker Compose with Monitoring Stack
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus

volumes:
  prometheus-data:
  grafana-data:
```

**Prometheus Configuration**
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['app:8000']
```

---

## Key Takeaways

✅ Use multi-stage builds to minimize image size  
✅ Implement health checks for all containers  
✅ Run containers as non-root users  
✅ Use specific image tags, avoid 'latest'  
✅ Implement proper logging and monitoring  
✅ Use secrets management (Azure Key Vault)  
✅ Set resource limits and requests  
✅ Use .dockerignore to reduce build context  
✅ Implement CI/CD pipelines for automation  
✅ Use ACR for private registry with geo-replication  
✅ Scan images for vulnerabilities  
✅ Use sidecar pattern for cross-cutting concerns  

---

**© Copyright Sivakumar J**
