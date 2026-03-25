# Lab 21: Azure Monitor

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Azure resources to monitor
- Log Analytics workspace

## Objective
Configure Azure Monitor for metrics, alerts, and dashboards.

---

## Create Log Analytics Workspace

```bash
# Create workspace
az monitor log-analytics workspace create \
  --resource-group rg-monitor-lab \
  --workspace-name law-monitoring \
  --location eastus \
  --sku PerGB2018

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-monitor-lab \
  --workspace-name law-monitoring \
  --query customerId -o tsv)
```

---

## Enable Monitoring for Resources

```bash
# Enable diagnostics for VM
az monitor diagnostic-settings create \
  --name vm-diagnostics \
  --resource <VM_RESOURCE_ID> \
  --workspace law-monitoring \
  --logs '[{"category": "Administrative", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'

# Enable for Storage Account
az monitor diagnostic-settings create \
  --name storage-diagnostics \
  --resource <STORAGE_ACCOUNT_ID> \
  --workspace law-monitoring \
  --logs '[{"category": "StorageRead", "enabled": true}, {"category": "StorageWrite", "enabled": true}]'

# Enable for App Service
az monitor diagnostic-settings create \
  --name app-diagnostics \
  --resource <APP_SERVICE_ID> \
  --workspace law-monitoring \
  --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}]'
```

---

## Create Metric Alerts

```bash
# Create action group
az monitor action-group create \
  --resource-group rg-monitor-lab \
  --name ag-ops-team \
  --short-name ops \
  --email-receiver name=admin email=admin@example.com

# Create CPU alert
az monitor metrics alert create \
  --resource-group rg-monitor-lab \
  --name alert-high-cpu \
  --description "Alert when CPU exceeds 80%" \
  --scopes <VM_RESOURCE_ID> \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-ops-team \
  --severity 2

# Create memory alert
az monitor metrics alert create \
  --resource-group rg-monitor-lab \
  --name alert-high-memory \
  --scopes <VM_RESOURCE_ID> \
  --condition "avg Available Memory Bytes < 1073741824" \
  --window-size 5m \
  --action ag-ops-team
```

---

## Create Log Query Alerts

```bash
# Create log alert
az monitor scheduled-query create \
  --resource-group rg-monitor-lab \
  --name alert-failed-logins \
  --scopes <WORKSPACE_ID> \
  --condition "count > 5" \
  --condition-query "SecurityEvent | where EventID == 4625 | summarize count() by Computer" \
  --description "Alert on failed login attempts" \
  --evaluation-frequency 5m \
  --window-size 10m \
  --action ag-ops-team \
  --severity 1
```

---

## Query Logs with KQL

```kusto
-- View all logs
AzureActivity
| take 100

-- Failed requests
requests
| where success == false
| summarize count() by resultCode
| order by count_ desc

-- High CPU usage
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where CounterValue > 80
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)

-- Application errors
traces
| where severityLevel >= 3
| project timestamp, message, severityLevel
| order by timestamp desc

-- Security events
SecurityEvent
| where EventID == 4625
| summarize FailedAttempts = count() by Account, Computer
| where FailedAttempts > 5
```

---

## Create Workbooks

```bash
# Create workbook (via Portal)
# Go to Azure Monitor → Workbooks → New
# Add queries, charts, and parameters
# Save workbook
```

**Sample workbook JSON:**
```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "Perf\n| where ObjectName == \"Processor\"\n| summarize avg(CounterValue) by bin(TimeGenerated, 5m)",
        "size": 0,
        "title": "CPU Usage Over Time",
        "queryType": 0,
        "visualization": "timechart"
      }
    }
  ]
}
```

---

## Create Dashboard

```bash
# Create dashboard (via Portal)
# Go to Azure Portal → Dashboard → New dashboard
# Add tiles: Metrics, Logs, Resource health
# Pin queries from Log Analytics
# Save and share dashboard
```

---

## Configure Autoscale

```bash
# Create autoscale setting
az monitor autoscale create \
  --resource-group rg-monitor-lab \
  --name autoscale-vmss \
  --resource <VMSS_ID> \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Add scale-out rule
az monitor autoscale rule create \
  --resource-group rg-monitor-lab \
  --autoscale-name autoscale-vmss \
  --condition "Percentage CPU > 75 avg 5m" \
  --scale out 1

# Add scale-in rule
az monitor autoscale rule create \
  --resource-group rg-monitor-lab \
  --autoscale-name autoscale-vmss \
  --condition "Percentage CPU < 25 avg 5m" \
  --scale in 1
```

---

## Key Takeaways
- Azure Monitor provides unified monitoring
- Metrics for real-time performance data
- Logs for detailed analysis with KQL
- Alerts notify on conditions
- Workbooks for custom visualizations
- Dashboards for overview
- Autoscale based on metrics
