# https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?pivots=development-environment-azure-cli

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

resource "azurerm_kubernetes_cluster" "aks-orbit-tst-use2-001" {
  name                = "aks-orbit-tst-use2-001"
  resource_group_name = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
  location            = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.log["log-orbitaks-tst-use2-001"].id
    msi_auth_for_monitoring_enabled = true
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = 1

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  linux_profile {
    admin_username = "fvadmin"

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  web_app_routing {
    dns_zone_ids = []
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-orbit-tst-use2-001_app1" {
  name                  = "app1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.id
  vm_size               = "Standard_A4_v2"
  node_count            = 1

  tags = {
    Environment = "Dev"
    Pool        = "app1"
  }
}

#region Output
output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.name
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config[0].password
  sensitive = true
}

output "cluster_username" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config[0].username
  sensitive = true
}

output "host" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config[0].host
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kube_config_raw
  sensitive = true
}
#endregion Output