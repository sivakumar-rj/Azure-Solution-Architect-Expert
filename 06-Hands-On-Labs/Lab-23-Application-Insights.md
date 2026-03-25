# Lab 23: Application Insights

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Web application (Node.js, .NET, Java, Python)
- Application Insights resource

## Objective
Implement Application Insights for application performance monitoring and diagnostics.

---

## Create Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app myapp-insights \
  --location eastus \
  --resource-group rg-appinsights-lab \
  --application-type web \
  --kind web

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app myapp-insights \
  --resource-group rg-appinsights-lab \
  --query instrumentationKey -o tsv)

# Get connection string
CONNECTION_STRING=$(az monitor app-insights component show \
  --app myapp-insights \
  --resource-group rg-appinsights-lab \
  --query connectionString -o tsv)
```

---

## Integrate with Node.js Application

**Install SDK:**
```bash
npm install applicationinsights
```

**app.js:**
```javascript
const appInsights = require('applicationinsights');
appInsights.setup('<CONNECTION_STRING>')
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .setSendLiveMetrics(true)
    .start();

const express = require('express');
const app = express();

app.get('/', (req, res) => {
    appInsights.defaultClient.trackEvent({name: 'HomePage visited'});
    res.send('Hello World!');
});

app.get('/api/data', async (req, res) => {
    const startTime = Date.now();
    try {
        // Simulate API call
        const data = await fetchData();
        appInsights.defaultClient.trackDependency({
            target: 'external-api',
            name: 'GET /data',
            data: 'https://api.example.com/data',
            duration: Date.now() - startTime,
            resultCode: 200,
            success: true
        });
        res.json(data);
    } catch (error) {
        appInsights.defaultClient.trackException({exception: error});
        res.status(500).send('Error');
    }
});

app.listen(3000);
```

---

## Custom Telemetry

```javascript
const client = appInsights.defaultClient;

// Track custom event
client.trackEvent({
    name: 'UserPurchase',
    properties: {
        userId: '12345',
        product: 'Premium Plan',
        amount: 99.99
    }
});

// Track custom metric
client.trackMetric({
    name: 'QueueLength',
    value: 42
});

// Track custom trace
client.trackTrace({
    message: 'Processing order',
    severity: appInsights.Contracts.SeverityLevel.Information,
    properties: {orderId: '67890'}
});

// Track page view
client.trackPageView({
    name: 'Product Page',
    url: 'https://example.com/products/123',
    duration: 1500
});

// Track request
client.trackRequest({
    name: 'GET /api/users',
    url: 'https://example.com/api/users',
    duration: 250,
    resultCode: 200,
    success: true
});
```

---

## Query Application Insights

```kusto
-- Failed requests
requests
| where success == false
| summarize count() by resultCode, name
| order by count_ desc

-- Slow requests
requests
| where duration > 1000
| project timestamp, name, url, duration, resultCode
| order by duration desc

-- Exception analysis
exceptions
| summarize count() by type, outerMessage
| order by count_ desc

-- Dependency failures
dependencies
| where success == false
| summarize count() by target, name
| order by count_ desc

-- Custom events
customEvents
| where name == "UserPurchase"
| extend amount = todouble(customDimensions.amount)
| summarize TotalRevenue = sum(amount), Purchases = count() by bin(timestamp, 1h)

-- User behavior
pageViews
| summarize Views = count() by name
| order by Views desc

-- Performance percentiles
requests
| summarize 
    P50 = percentile(duration, 50),
    P95 = percentile(duration, 95),
    P99 = percentile(duration, 99)
    by name
```

---

## Configure Availability Tests

```bash
# Create availability test (via Portal)
# Go to Application Insights → Availability → Add test
# Configure:
# - Test name
# - URL to test
# - Test frequency
# - Test locations
# - Success criteria
# - Alerts
```

**Availability test (multi-step):**
```xml
<WebTest>
  <Items>
    <Request Url="https://example.com" Method="GET" />
    <Request Url="https://example.com/login" Method="POST">
      <Body>username=test&password=test</Body>
    </Request>
    <Request Url="https://example.com/dashboard" Method="GET" />
  </Items>
</WebTest>
```

---

## Configure Smart Detection

```bash
# Smart Detection is enabled by default
# Configure via Portal:
# Go to Application Insights → Smart Detection
# Available detections:
# - Failure anomalies
# - Performance anomalies
# - Memory leak detection
# - Security detection
```

---

## Create Workbooks

```kusto
-- User journey analysis
let startEvent = "PageLoad";
let endEvent = "Purchase";
customEvents
| where name in (startEvent, endEvent)
| order by timestamp asc
| extend sessionId = tostring(customDimensions.sessionId)
| summarize 
    StartTime = minif(timestamp, name == startEvent),
    EndTime = maxif(timestamp, name == endEvent)
    by sessionId
| where isnotnull(StartTime) and isnotnull(EndTime)
| extend Duration = EndTime - StartTime
| summarize AvgDuration = avg(Duration), ConversionRate = count()
```

---

## Configure Alerts

```bash
# Create alert for failed requests
az monitor metrics alert create \
  --resource-group rg-appinsights-lab \
  --name alert-failed-requests \
  --scopes <APP_INSIGHTS_ID> \
  --condition "count requests/failed > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action <ACTION_GROUP_ID>

# Create alert for response time
az monitor metrics alert create \
  --resource-group rg-appinsights-lab \
  --name alert-slow-response \
  --scopes <APP_INSIGHTS_ID> \
  --condition "avg requests/duration > 2000" \
  --window-size 5m \
  --action <ACTION_GROUP_ID>
```

---

## Integrate with App Service

```bash
# Enable Application Insights for App Service
az webapp config appsettings set \
  --resource-group rg-appinsights-lab \
  --name myapp \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="<CONNECTION_STRING>"

# Enable for existing App Service
az monitor app-insights component connect-webapp \
  --resource-group rg-appinsights-lab \
  --app myapp-insights \
  --web-app myapp
```

---

## Sampling Configuration

```javascript
// Configure sampling
appInsights.setup('<CONNECTION_STRING>')
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true);

// Set sampling percentage
appInsights.defaultClient.config.samplingPercentage = 50; // 50% sampling

appInsights.start();
```

---

## Key Takeaways
- Application Insights monitors application performance
- Automatic collection of requests, dependencies, exceptions
- Custom telemetry for business metrics
- Availability tests monitor uptime
- Smart Detection identifies anomalies
- Powerful KQL queries for analysis
- Integration with App Service and AKS
- Sampling reduces costs for high-volume apps
