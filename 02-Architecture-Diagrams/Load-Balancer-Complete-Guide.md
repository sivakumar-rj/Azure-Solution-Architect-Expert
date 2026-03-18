# Azure Load Balancing Solutions - Complete Guide

## Load Balancer Comparison Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Azure Load Balancing Services                             │
├──────────────┬──────────┬──────────┬──────────┬──────────┬──────────────────┤
│   Service    │  Layer   │  Scope   │Protocol  │   Type   │   Use Case       │
├──────────────┼──────────┼──────────┼──────────┼──────────┼──────────────────┤
│Load Balancer │    4     │ Regional │ TCP/UDP  │ Network  │ VM load balance  │
│              │          │          │          │          │                  │
│App Gateway   │    7     │ Regional │HTTP/HTTPS│   Web    │ Web apps + WAF   │
│              │          │          │          │          │                  │
│Traffic Mgr   │   DNS    │  Global  │   All    │   DNS    │ DNS routing      │
│              │          │          │          │          │                  │
│Front Door    │    7     │  Global  │HTTP/HTTPS│   Web    │ Global web + CDN │
│              │          │          │          │          │                  │
│Azure Firewall│   3-7    │ Regional │   All    │ Security │ Outbound filter  │
│              │          │          │          │          │                  │
│Cross-region  │    4     │  Global  │ TCP/UDP  │ Network  │ Global TCP/UDP   │
│Load Balancer │          │          │          │          │                  │
└──────────────┴──────────┴──────────┴──────────┴──────────┴──────────────────┘
```

## 1. Azure Load Balancer (Layer 4)

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Azure Load Balancer                                   │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │              Public Load Balancer                              │     │
│  │                                                                │     │
│  │  Frontend IP: 52.x.x.x (Public IP)                            │     │
│  │  ┌──────────────────────────────────────────────────────┐     │     │
│  │  │  Load Balancing Rules                                │     │     │
│  │  │  - Rule 1: Port 80 → Backend Pool 1                  │     │     │
│  │  │  - Rule 2: Port 443 → Backend Pool 1                 │     │     │
│  │  │  - Rule 3: Port 3389 → NAT Pool (RDP)               │     │     │
│  │  └────────────────────┬─────────────────────────────────┘     │     │
│  │                       │                                        │     │
│  │  ┌────────────────────┼─────────────────────────────────┐     │     │
│  │  │  Health Probes                                       │     │     │
│  │  │  - HTTP Probe: /health (Port 80)                    │     │     │
│  │  │  - TCP Probe: Port 443                              │     │     │
│  │  │  - Interval: 15 seconds                             │     │     │
│  │  │  - Unhealthy threshold: 2                           │     │     │
│  │  └────────────────────┼─────────────────────────────────┘     │     │
│  │                       │                                        │     │
│  │  ┌────────────────────┼─────────────────────────────────┐     │     │
│  │  │  Backend Pool 1                                      │     │     │
│  │  │                    │                                 │     │     │
│  │  │  ┌─────────┐  ┌────┴────┐  ┌─────────┐             │     │     │
│  │  │  │  VM 1   │  │  VM 2   │  │  VM 3   │             │     │     │
│  │  │  │ Zone 1  │  │ Zone 2  │  │ Zone 3  │             │     │     │
│  │  │  │10.0.1.4 │  │10.0.1.5 │  │10.0.1.6 │             │     │     │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │     │     │
│  │  └──────────────────────────────────────────────────────┘     │     │
│  │                                                                │     │
│  │  Distribution Mode:                                            │     │
│  │  - 5-tuple hash (default): Source IP, Source Port,            │     │
│  │    Destination IP, Destination Port, Protocol                 │     │
│  │  - Source IP affinity (2-tuple): Source IP, Destination IP    │     │
│  │  - Source IP affinity (3-tuple): Source IP, Destination IP,   │     │
│  │    Protocol                                                    │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │              Internal Load Balancer                            │     │
│  │                                                                │     │
│  │  Frontend IP: 10.0.2.10 (Private IP)                          │     │
│  │  ┌──────────────────────────────────────────────────────┐     │     │
│  │  │  Backend Pool 2 (App Tier)                           │     │     │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │     │     │
│  │  │  │ App VM1 │  │ App VM2 │  │ App VM3 │             │     │     │
│  │  │  │10.0.2.4 │  │10.0.2.5 │  │10.0.2.6 │             │     │     │
│  │  │  └─────────┘  └─────────┘  └─────────┘             │     │     │
│  │  └──────────────────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  SKUs:                                                                   │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Basic (Free)                                                  │     │
│  │  - Up to 300 instances                                         │     │
│  │  - No SLA                                                      │     │
│  │  - No Availability Zones                                       │     │
│  │  - Basic health probes                                         │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Standard (Paid)                                               │     │
│  │  - Up to 1000 instances                                        │     │
│  │  - 99.99% SLA                                                  │     │
│  │  - Zone redundant                                              │     │
│  │  - Advanced diagnostics                                        │     │
│  │  - HA Ports                                                    │     │
│  │  - Outbound rules                                              │     │
│  └────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

## 2. Application Gateway (Layer 7)

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Application Gateway v2                                │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Frontend Configuration                                        │     │
│  │  - Public IP: 52.x.x.x                                         │     │
│  │  - Private IP: 10.0.1.10 (optional)                            │     │
│  │  - Ports: 80, 443                                              │     │
│  └────────────────────────┬───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  SSL/TLS Termination   │                                       │     │
│  │  - SSL Certificates    │                                       │     │
│  │  - SSL Policies        │                                       │     │
│  │  - End-to-end SSL      │                                       │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Web Application Firewall (WAF)                               │     │
│  │  - OWASP Top 10 protection                                    │     │
│  │  - SQL injection prevention                                   │     │
│  │  - XSS protection                                             │     │
│  │  - Bot protection                                             │     │
│  │  - Custom rules                                               │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Routing Rules          │                                      │     │
│  │                        │                                       │     │
│  │  Rule 1: Path-based routing                                   │     │
│  │  ┌─────────────────────┼──────────────────────────────────┐   │     │
│  │  │ /api/*              ▼                                  │   │     │
│  │  │ ──────────► Backend Pool 1 (API Servers)              │   │     │
│  │  │             ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │     │
│  │  │             │ API VM1 │  │ API VM2 │  │ API VM3 │    │   │     │
│  │  │             └─────────┘  └─────────┘  └─────────┘    │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  │                                                              │     │
│  │  Rule 2: Host-based routing                                 │     │
│  │  ┌──────────────────────────────────────────────────────┐   │     │
│  │  │ api.example.com                                      │   │     │
│  │  │ ──────────► Backend Pool 1 (API Servers)            │   │     │
│  │  │                                                      │   │     │
│  │  │ www.example.com                                      │   │     │
│  │  │ ──────────► Backend Pool 2 (Web Servers)            │   │     │
│  │  │             ┌─────────┐  ┌─────────┐  ┌─────────┐  │   │     │
│  │  │             │ Web VM1 │  │ Web VM2 │  │ Web VM3 │  │   │     │
│  │  │             └─────────┘  └─────────┘  └─────────┘  │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  │                                                              │     │
│  │  Rule 3: URL Rewrite                                         │     │
│  │  ┌──────────────────────────────────────────────────────┐   │     │
│  │  │ /old-path/* → /new-path/*                           │   │     │
│  │  │ Add/Remove headers                                   │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Advanced Features                                             │   │
│  │  - Session affinity (cookie-based)                            │   │
│  │  - Connection draining                                         │   │
│  │  - Custom health probes                                        │   │
│  │  - Autoscaling (2-125 instances)                              │   │
│  │  - Zone redundancy                                             │   │
│  │  - Private Link support                                        │   │
│  │  - HTTP/2 support                                              │   │
│  │  - WebSocket support                                           │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  SKUs:                                                                 │
│  - Standard_v2: Auto-scaling, zone redundancy                         │
│  - WAF_v2: Standard_v2 + Web Application Firewall                     │
│                                                                        │
│  Pricing: Per hour + Per GB processed                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

## 3. Azure Traffic Manager (DNS-based)

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Azure Traffic Manager                                 │
│                    (Global DNS Load Balancer)                            │
│                                                                          │
│  DNS Name: myapp.trafficmanager.net                                     │
│  TTL: 60 seconds                                                         │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Routing Methods                                               │     │
│  └────────────────────────┬───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  1. Performance Routing │                                      │     │
│  │     (Lowest latency)    │                                      │     │
│  │                         │                                      │     │
│  │  User in US ────────────┼──► East US Endpoint                 │     │
│  │  User in Europe ────────┼──► West Europe Endpoint             │     │
│  │  User in Asia ──────────┼──► Southeast Asia Endpoint          │     │
│  └─────────────────────────┼───────────────────────────────────────┘     │
│                            │                                            │
│  ┌─────────────────────────┼───────────────────────────────────────┐     │
│  │  2. Priority Routing    │                                      │     │
│  │     (Failover)          │                                      │     │
│  │                         │                                      │     │
│  │  Priority 1 (Primary) ──┼──► East US (Active)                 │     │
│  │  Priority 2 (Secondary)─┼──► West Europe (Standby)            │     │
│  │  Priority 3 (Tertiary)──┼──► Southeast Asia (Standby)         │     │
│  └─────────────────────────┼───────────────────────────────────────┘     │
│                            │                                            │
│  ┌─────────────────────────┼───────────────────────────────────────┐     │
│  │  3. Weighted Routing    │                                      │     │
│  │     (Traffic distribution)                                     │     │
│  │                         │                                      │     │
│  │  70% traffic ───────────┼──► East US                          │     │
│  │  20% traffic ───────────┼──► West Europe                      │     │
│  │  10% traffic ───────────┼──► Southeast Asia                   │     │
│  └─────────────────────────┼───────────────────────────────────────┘     │
│                            │                                            │
│  ┌─────────────────────────┼───────────────────────────────────────┐     │
│  │  4. Geographic Routing  │                                      │     │
│  │     (Data residency)    │                                      │     │
│  │                         │                                      │     │
│  │  North America ─────────┼──► East US                          │     │
│  │  Europe ────────────────┼──► West Europe                      │     │
│  │  Asia ──────────────────┼──► Southeast Asia                   │     │
│  └─────────────────────────┼───────────────────────────────────────┘     │
│                            │                                            │
│  ┌─────────────────────────┼───────────────────────────────────────┐     │
│  │  5. Multivalue Routing  │                                      │     │
│  │     (Return multiple IPs)                                      │     │
│  │                         │                                      │     │
│  │  Returns up to 8 healthy endpoints                            │     │
│  │  Client chooses which to use                                  │     │
│  └─────────────────────────┼───────────────────────────────────────┘     │
│                            │                                            │
│  ┌─────────────────────────┼───────────────────────────────────────┐     │
│  │  6. Subnet Routing      │                                      │     │
│  │     (IP range mapping)  │                                      │     │
│  │                         │                                      │     │
│  │  10.0.0.0/8 ────────────┼──► East US                          │     │
│  │  172.16.0.0/12 ─────────┼──► West Europe                      │     │
│  └─────────────────────────┼───────────────────────────────────────┘     │
│                            │                                            │
│  ┌─────────────────────────┴───────────────────────────────────────┐     │
│  │  Endpoints (Can be nested)                                     │     │
│  │                                                                │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │     │
│  │  │  East US     │  │ West Europe  │  │Southeast Asia│        │     │
│  │  │              │  │              │  │              │        │     │
│  │  │ - Azure VM   │  │ - Azure VM   │  │ - Azure VM   │        │     │
│  │  │ - App Service│  │ - App Service│  │ - App Service│        │     │
│  │  │ - Public IP  │  │ - Public IP  │  │ - Public IP  │        │     │
│  │  │ - External   │  │ - External   │  │ - External   │        │     │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Health Monitoring                                             │     │
│  │  - HTTP/HTTPS probes                                           │     │
│  │  - TCP probes                                                  │     │
│  │  - Interval: 30 seconds                                        │     │
│  │  - Timeout: 10 seconds                                         │     │
│  │  - Tolerated failures: 3                                       │     │
│  │  - Automatic failover                                          │     │
│  └────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

## 4. Azure Front Door (Global Layer 7)

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Azure Front Door                                      │
│                    (Global HTTP/HTTPS Load Balancer + CDN)               │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Global Edge Network (Microsoft's Anycast Network)            │     │
│  │  - 118+ Edge locations worldwide                              │     │
│  │  - Anycast IP (single IP, multiple locations)                 │     │
│  │  - SSL offloading at edge                                     │     │
│  └────────────────────────┬───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Frontend Host         │                                       │     │
│  │  - myapp.azurefd.net   │                                       │     │
│  │  - Custom domain: www.example.com                             │     │
│  │  - SSL certificate (managed or custom)                        │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Web Application Firewall (WAF)                               │     │
│  │  - Microsoft managed rules                                    │     │
│  │  - Custom rules                                               │     │
│  │  - Bot protection                                             │     │
│  │  - Rate limiting                                              │     │
│  │  - Geo-filtering                                              │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Routing Rules          │                                      │     │
│  │                        │                                       │     │
│  │  ┌─────────────────────┼──────────────────────────────────┐   │     │
│  │  │ Path: /api/*        ▼                                  │   │     │
│  │  │ ──────────► Backend Pool 1 (API)                      │   │     │
│  │  │             Priority: 1 (East US)                     │   │     │
│  │  │             Priority: 2 (West Europe)                 │   │     │
│  │  │             Priority: 3 (Southeast Asia)              │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  │                                                              │     │
│  │  ┌──────────────────────────────────────────────────────┐   │     │
│  │  │ Path: /images/*                                      │   │     │
│  │  │ ──────────► Backend Pool 2 (Storage)                │   │     │
│  │  │             Caching: Enabled (1 day)                 │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  │                                                              │     │
│  │  ┌──────────────────────────────────────────────────────┐   │     │
│  │  │ Path: /*                                             │   │     │
│  │  │ ──────────► Backend Pool 3 (Web)                    │   │     │
│  │  │             Session affinity: Enabled                │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Backend Pools                                                 │   │
│  │                                                                │   │
│  │  Pool 1: API Servers                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │   │
│  │  │  East US     │  │ West Europe  │  │Southeast Asia│        │   │
│  │  │  Weight: 50  │  │  Weight: 30  │  │  Weight: 20  │        │   │
│  │  │  Priority: 1 │  │  Priority: 1 │  │  Priority: 1 │        │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘        │   │
│  │                                                                │   │
│  │  Pool 2: Storage Accounts                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐                          │   │
│  │  │  Blob Storage│  │  CDN Origin  │                          │   │
│  │  │  (Primary)   │  │  (Secondary) │                          │   │
│  │  └──────────────┘  └──────────────┘                          │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Advanced Features                                             │   │
│  │  - URL rewrite and redirect                                    │   │
│  │  - Custom domains with SSL                                     │   │
│  │  - Caching (query string, compression)                         │   │
│  │  - Session affinity                                            │   │
│  │  - Health probes (HTTP/HTTPS)                                  │   │
│  │  - Load balancing (Latency, Priority, Weighted, Session)       │   │
│  │  - Private Link to backends                                    │   │
│  │  - Rules engine (advanced routing)                             │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  SKUs:                                                                 │
│  - Classic: Legacy (deprecated)                                       │
│  - Standard: Basic features                                           │
│  - Premium: Standard + Private Link + Advanced WAF                    │
│                                                                        │
│  Pricing: Per GB outbound + Per routing rule                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

**© Copyright Sivakumar J**

## 5. Cross-Region Load Balancer (Global Layer 4)

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                Cross-Region Load Balancer                                │
│                (Global TCP/UDP Load Balancer)                            │
│                                                                          │
│  Frontend IP: 52.x.x.x (Anycast Global IP)                              │
│  Protocol: TCP/UDP                                                       │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Global Distribution                                           │     │
│  │  - Single anycast IP                                           │     │
│  │  - Instant regional failover                                   │     │
│  │  - No DNS dependency                                            │     │
│  │  - Sub-second failover                                          │     │
│  └────────────────────────┬───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Backend Pool (Regional Load Balancers)                       │     │
│  │                        │                                       │     │
│  │  ┌─────────────────────┼──────────────────────────────────┐   │     │
│  │  │ Region 1: East US   ▼                                  │   │     │
│  │  │ ┌────────────────────────────────────────────────┐     │   │     │
│  │  │ │  Regional Standard Load Balancer               │     │   │     │
│  │  │ │  Frontend IP: 10.10.1.10                       │     │   │     │
│  │  │ │  ┌──────────┐  ┌──────────┐  ┌──────────┐    │     │   │     │
│  │  │ │  │  VM 1    │  │  VM 2    │  │  VM 3    │    │     │   │     │
│  │  │ │  │  Zone 1  │  │  Zone 2  │  │  Zone 3  │    │     │   │     │
│  │  │ │  └──────────┘  └──────────┘  └──────────┘    │     │   │     │
│  │  │ └────────────────────────────────────────────────┘     │   │     │
│  │  └──────────────────────────────────────────────────────────┘   │     │
│  │                                                              │     │
│  │  ┌──────────────────────────────────────────────────────┐   │     │
│  │  │ Region 2: West Europe                                │   │     │
│  │  │ ┌────────────────────────────────────────────────┐   │   │     │
│  │  │ │  Regional Standard Load Balancer               │   │   │     │
│  │  │ │  Frontend IP: 10.20.1.10                       │   │   │     │
│  │  │ │  ┌──────────┐  ┌──────────┐  ┌──────────┐    │   │   │     │
│  │  │ │  │  VM 1    │  │  VM 2    │  │  VM 3    │    │   │   │     │
│  │  │ │  │  Zone 1  │  │  Zone 2  │  │  Zone 3  │    │   │   │     │
│  │  │ │  └──────────┘  └──────────┘  └──────────┘    │   │   │     │
│  │  │ └────────────────────────────────────────────────┘   │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  │                                                              │     │
│  │  ┌──────────────────────────────────────────────────────┐   │     │
│  │  │ Region 3: Southeast Asia                             │   │     │
│  │  │ ┌────────────────────────────────────────────────┐   │   │     │
│  │  │ │  Regional Standard Load Balancer               │   │   │     │
│  │  │ │  Frontend IP: 10.30.1.10                       │   │   │     │
│  │  │ │  ┌──────────┐  ┌──────────┐  ┌──────────┐    │   │   │     │
│  │  │ │  │  VM 1    │  │  VM 2    │  │  VM 3    │    │   │   │     │
│  │  │ │  │  Zone 1  │  │  Zone 2  │  │  Zone 3  │    │   │   │     │
│  │  │ │  └──────────┘  └──────────┘  └──────────┘    │   │   │     │
│  │  │ └────────────────────────────────────────────────┘   │   │     │
│  │  └──────────────────────────────────────────────────────┘   │     │
│  └──────────────────────────────────────────────────────────────┘     │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Health Probes                                                 │   │
│  │  - Monitors regional load balancers                            │   │
│  │  - Automatic failover on failure                               │   │
│  │  - No manual intervention                                      │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  Use Cases:                                                            │
│  - Gaming (low latency TCP/UDP)                                       │
│  - IoT (MQTT, CoAP)                                                   │
│  - Real-time communications                                           │
│  - Database replication                                               │
└─────────────────────────────────────────────────────────────────────────┘
```

## 6. Azure Firewall (Layer 3-7)

### Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Azure Firewall                                        │
│                    (Managed Network Security)                            │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Deployment                                                    │     │
│  │  - Dedicated subnet: AzureFirewallSubnet (/26 minimum)        │     │
│  │  - Public IP: 52.x.x.x (for outbound)                         │     │
│  │  - Private IP: 10.0.1.4 (for inbound from VNet)               │     │
│  └────────────────────────┬───────────────────────────────────────┘     │
│                           │                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Network Rules (Layer 3-4)                                    │     │
│  │                        │                                       │     │
│  │  Rule 1: Allow HTTP/HTTPS to Internet                         │     │
│  │  - Source: 10.0.0.0/16                                         │     │
│  │  - Destination: *                                              │     │
│  │  - Ports: 80, 443                                              │     │
│  │  - Protocol: TCP                                               │     │
│  │  - Action: Allow                                               │     │
│  │                                                                │     │
│  │  Rule 2: Allow DNS                                             │     │
│  │  - Source: 10.0.0.0/16                                         │     │
│  │  - Destination: *                                              │     │
│  │  - Port: 53                                                    │     │
│  │  - Protocol: UDP                                               │     │
│  │  - Action: Allow                                               │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Application Rules (Layer 7)                                   │     │
│  │                                                                │     │
│  │  Rule 1: Allow specific FQDNs                                  │     │
│  │  - Source: 10.0.0.0/16                                         │     │
│  │  - Target FQDNs:                                               │     │
│  │    * *.microsoft.com                                           │     │
│  │    * *.azure.com                                               │     │
│  │    * *.github.com                                              │     │
│  │  - Protocol: HTTPS                                             │     │
│  │  - Action: Allow                                               │     │
│  │                                                                │     │
│  │  Rule 2: Block social media                                    │     │
│  │  - Source: 10.0.0.0/16                                         │     │
│  │  - Target FQDNs:                                               │     │
│  │    * *.facebook.com                                            │     │
│  │    * *.twitter.com                                             │     │
│  │  - Action: Deny                                                │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  NAT Rules (DNAT)                                              │     │
│  │                                                                │     │
│  │  Rule 1: Publish web server                                    │     │
│  │  - Destination: 52.x.x.x (Public IP)                          │     │
│  │  - Port: 443                                                   │     │
│  │  - Translated to: 10.0.1.10:443                               │     │
│  │                                                                │     │
│  │  Rule 2: Publish RDP                                           │     │
│  │  - Destination: 52.x.x.x (Public IP)                          │     │
│  │  - Port: 3389                                                  │     │
│  │  - Translated to: 10.0.2.10:3389                              │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Threat Intelligence (Premium)                                 │     │
│  │  - Microsoft threat intelligence feed                          │     │
│  │  - Alert and deny mode                                         │     │
│  │  - Known malicious IPs/domains                                 │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  IDPS (Intrusion Detection/Prevention) - Premium              │     │
│  │  - Signature-based detection                                   │     │
│  │  - Alert or Alert and Deny mode                                │     │
│  │  - Bypass rules for false positives                            │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  TLS Inspection (Premium)                                      │     │
│  │  - Decrypt and inspect HTTPS traffic                           │     │
│  │  - Re-encrypt before forwarding                                │     │
│  │  - Requires Key Vault integration                              │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  SKUs:                                                                   │
│  - Basic: Small deployments, limited features                           │
│  - Standard: Production workloads                                       │
│  - Premium: Advanced security (IDPS, TLS inspection)                    │
│                                                                          │
│  Pricing: Per hour + Per GB processed                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Load Balancer Decision Tree

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Which Load Balancer to Use?                           │
│                                                                          │
│  Start: What protocol?                                                   │
│  ├─ HTTP/HTTPS                                                          │
│  │  ├─ Global distribution needed?                                      │
│  │  │  ├─ Yes → Azure Front Door                                        │
│  │  │  │  - Global anycast                                              │
│  │  │  │  - CDN capabilities                                            │
│  │  │  │  - WAF at edge                                                 │
│  │  │  │  - Best for: Web apps, APIs, media                             │
│  │  │  │                                                                │
│  │  │  └─ No → Regional only?                                           │
│  │  │     └─ Application Gateway                                        │
│  │  │        - Layer 7 features                                         │
│  │  │        - WAF protection                                           │
│  │  │        - SSL offload                                              │
│  │  │        - Best for: Regional web apps                              │
│  │  │                                                                   │
│  │  └─ Need DNS-based routing?                                          │
│  │     └─ Traffic Manager                                               │
│  │        - DNS-based                                                   │
│  │        - Protocol agnostic                                           │
│  │        - Best for: Multi-region failover                             │
│  │                                                                       │
│  ├─ TCP/UDP                                                             │
│  │  ├─ Global distribution needed?                                      │
│  │  │  ├─ Yes → Cross-Region Load Balancer                              │
│  │  │  │  - Global anycast IP                                           │
│  │  │  │  - Instant failover                                            │
│  │  │  │  - Best for: Gaming, IoT, real-time                            │
│  │  │  │                                                                │
│  │  │  └─ No → Regional only?                                           │
│  │  │     └─ Azure Load Balancer (Standard)                             │
│  │  │        - Layer 4                                                  │
│  │  │        - Zone redundant                                           │
│  │  │        - Best for: VMs, containers                                │
│  │  │                                                                   │
│  │  └─ Need DNS-based routing?                                          │
│  │     └─ Traffic Manager                                               │
│  │                                                                       │
│  └─ Need security filtering?                                            │
│     └─ Azure Firewall                                                   │
│        - Layer 3-7 filtering                                            │
│        - IDPS (Premium)                                                 │
│        - TLS inspection (Premium)                                       │
│        - Best for: Hub-spoke, outbound filtering                        │
└─────────────────────────────────────────────────────────────────────────┘
```

## Combined Architecture Example

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Complete Load Balancing Stack                         │
│                                                                          │
│  Layer 1: Global DNS                                                     │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Traffic Manager (DNS)                                         │     │
│  │  - Performance routing                                         │     │
│  │  - Health monitoring                                           │     │
│  └────────────────────────┬───────────────────────────────────────┘     │
│                           │                                             │
│  Layer 2: Global HTTP/HTTPS                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Azure Front Door      │                                       │     │
│  │  - WAF at edge         │                                       │     │
│  │  - CDN caching         │                                       │     │
│  │  - SSL offload         │                                       │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  Layer 3: Regional HTTP/HTTPS                                           │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Application Gateway   │                                       │     │
│  │  - Path-based routing  │                                       │     │
│  │  - WAF (regional)      │                                       │     │
│  │  - Session affinity    │                                       │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  Layer 4: VM Load Balancing                                             │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Azure Load Balancer   │                                       │     │
│  │  - Layer 4 TCP/UDP     │                                       │     │
│  │  - Zone redundant      │                                       │     │
│  │  - HA Ports            │                                       │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│  Layer 5: Security                                                      │
│  ┌────────────────────────┼───────────────────────────────────────┐     │
│  │  Azure Firewall        │                                       │     │
│  │  - Outbound filtering  │                                       │     │
│  │  - IDPS                │                                       │     │
│  │  - Threat intelligence │                                       │     │
│  └────────────────────────┼───────────────────────────────────────┘     │
│                           │                                             │
│                           ▼                                             │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │  Backend Resources                                             │     │
│  │  - VMs                                                         │     │
│  │  - VM Scale Sets                                               │     │
│  │  - AKS                                                         │     │
│  │  - App Service                                                 │     │
│  └────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Exam Points

✅ **Load Balancer (Layer 4)**
- Regional, TCP/UDP
- Standard SKU for production (zone redundant, SLA)
- Use for VMs, VMSS

✅ **Application Gateway (Layer 7)**
- Regional, HTTP/HTTPS only
- WAF, SSL offload, path-based routing
- Use for web applications

✅ **Traffic Manager (DNS)**
- Global, protocol agnostic
- DNS-based routing (60s TTL)
- Use for multi-region failover

✅ **Front Door (Layer 7)**
- Global, HTTP/HTTPS
- Anycast, CDN, WAF at edge
- Use for global web apps

✅ **Cross-Region LB (Layer 4)**
- Global, TCP/UDP
- Anycast, instant failover
- Use for gaming, IoT

✅ **Azure Firewall (Layer 3-7)**
- Regional, all protocols
- IDPS, TLS inspection (Premium)
- Use for security filtering

---

**© Copyright Sivakumar J**
