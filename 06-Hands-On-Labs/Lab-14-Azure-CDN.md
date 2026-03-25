# Lab 14: Azure CDN

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Storage account or web app
- Custom domain (optional)

## Objective
Configure Azure CDN for content delivery with caching and custom domains.

---

## Create CDN Profile and Endpoint

```bash
# Create resource group
az group create --name rg-cdn-lab --location eastus

# Create storage account for origin
az storage account create \
  --name stcdnorigin$RANDOM \
  --resource-group rg-cdn-lab \
  --location eastus \
  --sku Standard_LRS

# Enable static website
az storage blob service-properties update \
  --account-name stcdnorigin$RANDOM \
  --static-website \
  --index-document index.html

# Create CDN profile
az cdn profile create \
  --resource-group rg-cdn-lab \
  --name cdn-profile \
  --sku Standard_Microsoft

# Create CDN endpoint
az cdn endpoint create \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --origin stcdnorigin$RANDOM.z13.web.core.windows.net \
  --origin-host-header stcdnorigin$RANDOM.z13.web.core.windows.net \
  --enable-compression true
```

---

## Configure Caching Rules

```bash
# Set caching behavior
az cdn endpoint update \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --query-string-caching-behavior IgnoreQueryString

# Create caching rule
az cdn endpoint rule add \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --order 1 \
  --rule-name CacheImages \
  --match-variable UrlFileExtension \
  --operator Equal \
  --match-values jpg png gif \
  --action-name CacheExpiration \
  --cache-behavior Override \
  --cache-duration 7.00:00:00
```

---

## Configure Custom Domain

```bash
# Add custom domain
az cdn custom-domain create \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --endpoint-name cdn-endpoint-$RANDOM \
  --name custom-domain \
  --hostname www.example.com

# Enable HTTPS
az cdn custom-domain enable-https \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --endpoint-name cdn-endpoint-$RANDOM \
  --name custom-domain
```

---

## Configure Compression

```bash
# Enable compression
az cdn endpoint update \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --enable-compression true \
  --content-types-to-compress \
    "text/plain" \
    "text/html" \
    "text/css" \
    "application/javascript" \
    "application/json"
```

---

## Purge CDN Cache

```bash
# Purge all content
az cdn endpoint purge \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --content-paths '/*'

# Purge specific paths
az cdn endpoint purge \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --content-paths '/images/*' '/css/style.css'
```

---

## Verification Steps

```bash
# Get endpoint hostname
az cdn endpoint show \
  --resource-group rg-cdn-lab \
  --profile-name cdn-profile \
  --name cdn-endpoint-$RANDOM \
  --query hostName -o tsv

# Test CDN
curl -I https://<ENDPOINT>.azureedge.net
```

---

## Cleanup

```bash
az group delete --name rg-cdn-lab --yes --no-wait
```

---

## Key Takeaways
- CDN reduces latency with edge caching
- Supports custom domains and HTTPS
- Compression reduces bandwidth
- Caching rules optimize performance
- Purge cache for content updates
- Multiple SKUs: Microsoft, Verizon, Akamai
