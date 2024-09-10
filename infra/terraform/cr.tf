resource "azurerm_container_registry" "cr" {
  name                = "crorbittst001"
  resource_group_name = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].name
  location            = azurerm_resource_group.rg["rg-orbit-tst-use2-001"].location
  sku                 = "Basic"
}

resource "azurerm_role_assignment" "cr" {
  principal_id                     = azurerm_kubernetes_cluster.aks-orbit-tst-use2-001.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.cr.id
  skip_service_principal_aad_check = true
}