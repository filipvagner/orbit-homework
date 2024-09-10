# https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-monitoring-enable?toc=%2Fazure%2Faks%2Ftoc.json&bc=%2Fazure%2Faks%2Fbreadcrumb%2Ftoc.json&tabs=terraform#enable-prometheus-and-grafana

#region Log Analytics Workspace
locals {
  logs = {
    log-orbitaks-tst-use2-001 = {
      name                            = "log-orbitaks-tst-use2-001"
      resource_group_name             = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
      location                        = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
      allow_resource_only_permissions = true
      cmk_for_query_forced            = false
      sku                             = "PerGB2018"
      retention_in_days               = 30
      daily_quota_gb                  = -1
      internet_ingestion_enabled      = true
      local_authentication_disabled   = false
      tags = merge(
        azurerm_resource_group.rg["rg-orbit-tst-use2-001"].tags,
      )
    }
  }
}

resource "azurerm_log_analytics_workspace" "log" {
  for_each = {
    for log_name, log in local.logs : log_name => log
    if lookup(log, "existing_resource", null) == null
  }

  name                            = each.value.name
  resource_group_name             = each.value.resource_group_name
  location                        = each.value.location
  allow_resource_only_permissions = each.value.allow_resource_only_permissions
  cmk_for_query_forced            = each.value.cmk_for_query_forced
  sku                             = each.value.sku
  retention_in_days               = each.value.retention_in_days
  daily_quota_gb                  = each.value.daily_quota_gb
  internet_ingestion_enabled      = each.value.internet_ingestion_enabled
  local_authentication_disabled   = each.value.local_authentication_disabled
  tags                            = each.value.tags
}
#endregion Log Analytics Workspace

#region Azure Monitor Workspace
resource "azurerm_monitor_workspace" "amw" {
  name                = "amw-orbitaks-tst-use2-001"
  resource_group_name = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
  location            = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
}
#endregion Azure Monitor Workspace

#region Data Collection Rule
resource "azurerm_monitor_data_collection_rule" "dcr-ci" {
  name                = "dcr-orbitaks-tst-use2-001"
  resource_group_name = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
  location            = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
  description         = "DCR for Azure Monitor Container Insights"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.log["log-orbitaks-tst-use2-001"].id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory", "Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory", "Microsoft-ContainerNodeInventory", "Microsoft-Perf"]
    destinations = ["ciworkspace"]
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["ciworkspace"]
  }

  data_sources {
    syslog {
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
      log_levels     = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "sysLogsDataSource"
    }

    extension {
      name           = "ContainerInsightsExtension"
      streams        = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory", "Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory", "Microsoft-ContainerNodeInventory", "Microsoft-Perf"]
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        "dataCollectionSettings" : {
          "interval" : "1m",
          "namespaceFilteringMode" : "Off",
          "namespaces" : ["kube-system"]
          "enableContainerLogV2" : true
        }
      })
    }
  }


}

resource "azurerm_monitor_data_collection_rule_association" "dcra-ci" {
  name                    = "dcra-orbitaks-tst-use2-001"
  target_resource_id      = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr-ci.id
  description             = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS Cluster."
}

resource "azurerm_monitor_data_collection_endpoint" "dce-prometheus" {
  name                = "dce-orbitaksprometheus-tst-use2-001"
  resource_group_name = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
  location            = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "dcr-prometheus" {
  name                        = "dcr-orbitaksprometheus-tst-use2-001"
  resource_group_name         = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
  location                    = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-prometheus.id
  kind                        = "Linux"
  description                 = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.amw.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  depends_on = [
    azurerm_monitor_data_collection_endpoint.dce-prometheus
  ]
}
#endregion Data Collection Rule