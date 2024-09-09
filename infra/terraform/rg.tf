locals {
  resource_groups = {
    rg-orbit-tst-use2-001 = {
      name     = "rg-orbit-tst-use2-001"
      location = "East US 2"
      tags = {
        Application = "AKS Deployment",
        Importance  = "Low",
        Environment = "Test",
      }
    },
  }
}

resource "azurerm_resource_group" "rg" {
  for_each = {
    for resource_group_name, resource_group in local.resource_groups : resource_group_name => resource_group
    if lookup(resource_group, "existing_resource", null) == null
  }

  name     = each.value.name
  location = each.value.location

  tags = merge(
    lookup(each.value, "tags", null)
  )

  timeouts {
    create = "15m"
    delete = "15m"
  }
}