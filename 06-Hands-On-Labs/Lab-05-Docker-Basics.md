# Lab 05: Docker Basics

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure VM or local machine with Docker installed
- Basic understanding of containers
- Docker Hub account (optional)

## Objective
Learn Docker fundamentals: images, containers, volumes, and networking.

---

## Install Docker

### On Ubuntu/Debian
```bash
# Update packages
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker run hello-world
```

---

## Basic Docker Commands

### Working with Images
```bash
# Pull image from Docker Hub
docker pull nginx:latest
docker pull node:20-alpine

# List images
docker images

# Search for images
docker search nginx

# Remove image
docker rmi nginx:latest

# Build image from Dockerfile
docker build -t myapp:v1 .

# Tag image
docker tag myapp:v1 myapp:latest

# Push to Docker Hub
docker login
docker push <username>/myapp:v1
```

### Working with Containers
```bash
# Run container
docker run -d --name web nginx:latest

# Run with port mapping
docker run -d -p 8080:80 --name web nginx

# Run with environment variables
docker run -d -e NODE_ENV=production --name app node:20-alpine

# Run interactively
docker run -it ubuntu:22.04 /bin/bash

# List running containers
docker ps

# List all containers
docker ps -a

# Stop container
docker stop web

# Start container
docker start web

# Restart container
docker restart web

# Remove container
docker rm web

# Remove running container (force)
docker rm -f web

# View logs
docker logs web
docker logs -f web  # Follow logs

# Execute command in running container
docker exec -it web /bin/bash

# Inspect container
docker inspect web

# View container stats
docker stats web
```

---

## Create Custom Docker Image

### Simple Node.js Application

**app.js**
```javascript
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello from Docker!', version: '1.0' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});
```

**package.json**
```json
{
  "name": "docker-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.18.0"
  }
}
```

**Dockerfile**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

**.dockerignore**
```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

### Build and Run
```bash
# Build image
docker build -t myapp:1.0 .

# Run container
docker run -d -p 3000:3000 --name myapp myapp:1.0

# Test
curl http://localhost:3000
curl http://localhost:3000/health

# View logs
docker logs myapp
```

---

## Docker Volumes

```bash
# Create volume
docker volume create mydata

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Run container with volume
docker run -d -v mydata:/data --name db postgres:15

# Run with bind mount
docker run -d -v $(pwd)/data:/data --name app nginx

# Remove volume
docker volume rm mydata

# Remove unused volumes
docker volume prune
```

---

## Docker Networking

```bash
# List networks
docker network ls

# Create network
docker network create mynetwork

# Inspect network
docker network inspect mynetwork

# Run container on network
docker run -d --network mynetwork --name web nginx
docker run -d --network mynetwork --name app node:20-alpine

# Connect container to network
docker network connect mynetwork db

# Disconnect container from network
docker network disconnect mynetwork db

# Remove network
docker network rm mynetwork
```

---

## Multi-Container Application

**docker-compose.yml**
```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - app-network
    depends_on:
      - api

  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    networks:
      - app-network
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=secret
      - POSTGRES_DB=myapp
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  db-data:
```

### Docker Compose Commands
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# List services
docker-compose ps

# Stop services
docker-compose stop

# Start services
docker-compose start

# Restart services
docker-compose restart

# Remove services
docker-compose down

# Remove with volumes
docker-compose down -v

# Scale service
docker-compose up -d --scale api=3
```

---

## Best Practices

### Optimize Dockerfile
```dockerfile
# Use specific version tags
FROM node:20-alpine

# Use multi-stage builds
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

### Security
```bash
# Run as non-root user
FROM node:20-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs

# Scan for vulnerabilities
docker scan myapp:1.0

# Use read-only filesystem
docker run --read-only -v /tmp --name app myapp:1.0
```

---

## Verification Steps

1. **Check Docker status:**
```bash
docker info
docker version
```

2. **Test container:**
```bash
docker run --rm alpine:latest echo "Hello Docker"
```

3. **Monitor resources:**
```bash
docker stats --no-stream
```

---

## Troubleshooting

**Issue: Permission denied**
- Add user to docker group: `sudo usermod -aG docker $USER`
- Logout and login again

**Issue: Container exits immediately**
- Check logs: `docker logs <container>`
- Verify CMD/ENTRYPOINT in Dockerfile
- Ensure application doesn't exit

**Issue: Port already in use**
- Check running containers: `docker ps`
- Use different port: `-p 8081:80`
- Stop conflicting service

**Issue: Image build fails**
- Check Dockerfile syntax
- Verify base image exists
- Review build context size

---

## Cleanup

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Remove all volumes
docker volume prune -f

# Remove all networks
docker network prune -f

# Complete cleanup
docker system prune -a --volumes -f
```

---

## Key Takeaways
- Docker containers are lightweight and portable
- Images are built from Dockerfiles
- Volumes persist data beyond container lifecycle
- Networks enable container communication
- Docker Compose manages multi-container applications
- Always use specific image tags in production
- Multi-stage builds reduce image size
- Run containers as non-root for security
