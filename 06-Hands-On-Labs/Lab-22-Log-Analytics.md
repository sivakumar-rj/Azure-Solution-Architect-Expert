# Lab 22: Log Analytics

**Last Updated: March 2026**
**© Copyright Sivakumar J**

---

## Prerequisites
- Azure subscription
- Log Analytics workspace
- Resources sending logs

## Objective
Master Log Analytics with KQL queries, solutions, and analysis.

---

## Advanced KQL Queries

```kusto
-- Performance analysis
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue), MaxCPU = max(CounterValue) by Computer
| where AvgCPU > 50
| order by AvgCPU desc

-- Application insights
requests
| where timestamp > ago(24h)
| summarize 
    TotalRequests = count(),
    FailedRequests = countif(success == false),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95)
    by bin(timestamp, 1h)
| extend FailureRate = (FailedRequests * 100.0) / TotalRequests

-- Security analysis
SecurityEvent
| where TimeGenerated > ago(7d)
| where EventID in (4624, 4625)
| summarize 
    SuccessfulLogins = countif(EventID == 4624),
    FailedLogins = countif(EventID == 4625)
    by Account, Computer
| where FailedLogins > 10
| project Account, Computer, SuccessfulLogins, FailedLogins, 
    FailureRatio = (FailedLogins * 1.0) / (SuccessfulLogins + FailedLogins)
| order by FailedLogins desc

-- Network traffic analysis
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(1h)
| summarize TotalBytes = sum(BytesSent_d + BytesReceived_d) by SrcIP_s, DestIP_s
| top 10 by TotalBytes desc

-- Resource usage trends
AzureMetrics
| where TimeGenerated > ago(30d)
| where MetricName == "Percentage CPU"
| summarize AvgCPU = avg(Average) by bin(TimeGenerated, 1d), Resource
| render timechart

-- Join multiple tables
Heartbeat
| where TimeGenerated > ago(1h)
| join kind=inner (
    Perf
    | where ObjectName == "Processor"
    | summarize AvgCPU = avg(CounterValue) by Computer
) on Computer
| project Computer, TimeGenerated, AvgCPU, OSType, ComputerIP
```

---

## Create Functions

```kusto
-- Create function
.create function GetHighCPU() {
    Perf
    | where ObjectName == "Processor" and CounterName == "% Processor Time"
    | where CounterValue > 80
    | summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
}

-- Use function
GetHighCPU()
| where TimeGenerated > ago(1h)
```

---

## Configure Data Collection Rules

```bash
# Create data collection rule
az monitor data-collection rule create \
  --resource-group rg-monitor-lab \
  --name dcr-windows-events \
  --location eastus \
  --rule-file dcr.json

# Associate with VM
az monitor data-collection rule association create \
  --resource-group rg-monitor-lab \
  --name dcr-association \
  --rule-id <DCR_ID> \
  --resource <VM_ID>
```

**dcr.json:**
```json
{
  "properties": {
    "dataSources": {
      "performanceCounters": [
        {
          "name": "perfCounterDataSource",
          "streams": ["Microsoft-Perf"],
          "samplingFrequencyInSeconds": 60,
          "counterSpecifiers": [
            "\\Processor(_Total)\\% Processor Time",
            "\\Memory\\Available Bytes"
          ]
        }
      ],
      "windowsEventLogs": [
        {
          "name": "eventLogsDataSource",
          "streams": ["Microsoft-Event"],
          "xPathQueries": [
            "System!*[System[(Level=1 or Level=2 or Level=3)]]",
            "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
          ]
        }
      ]
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "<WORKSPACE_ID>",
          "name": "centralWorkspace"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": ["Microsoft-Perf", "Microsoft-Event"],
        "destinations": ["centralWorkspace"]
      }
    ]
  }
}
```

---

## Install Solutions

```bash
# Install VM Insights
az vm extension set \
  --resource-group rg-monitor-lab \
  --vm-name myvm \
  --name DependencyAgentLinux \
  --publisher Microsoft.Azure.Monitoring.DependencyAgent

az vm extension set \
  --resource-group rg-monitor-lab \
  --vm-name myvm \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings '{"workspaceId":"<WORKSPACE_ID>"}' \
  --protected-settings '{"workspaceKey":"<WORKSPACE_KEY>"}'
```

---

## Export and Archive Logs

```bash
# Export to Storage Account
az monitor log-analytics workspace data-export create \
  --resource-group rg-monitor-lab \
  --workspace-name law-monitoring \
  --name export-to-storage \
  --destination <STORAGE_ACCOUNT_ID> \
  --tables Syslog SecurityEvent

# Export to Event Hub
az monitor log-analytics workspace data-export create \
  --resource-group rg-monitor-lab \
  --workspace-name law-monitoring \
  --name export-to-eventhub \
  --destination <EVENT_HUB_ID> \
  --tables AzureActivity
```

---

## Key Takeaways
- KQL is powerful query language
- Functions reuse common queries
- Data collection rules control ingestion
- Solutions provide pre-built insights
- Export for long-term retention
- Join tables for correlation
- Aggregations for analysis
