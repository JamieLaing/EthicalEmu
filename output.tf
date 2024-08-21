output "location" {
  description = "The Azure region"
  value       = azurerm_resource_group.sh.location
}

output "resource_group_name" {
  description = "The Azure resource group"
  value       = azurerm_resource_group.sh.name
}

output "machines" {
  value = [
    for vm in azurerm_windows_virtual_machine.vm : {
      name = vm.name
      id   = vm.id
      ip   = vm.private_ip_address
    }
  ]
}