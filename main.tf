#Create a single resource group for all resources
resource "azurerm_resource_group" "sh" {
  name     = "Ethical-Emu"
  location = var.resource_group_location
}

//generate a random string of 6 lowercase characters
resource "random_string" "chars" {
  length    = 6
  special   = false
  upper     = false
  numeric   = false
  min_lower = 6
}

# Create a virtual network for all VMs
resource "azurerm_virtual_network" "vnet" {
  for_each            = var.customers
  address_space       = ["${each.value.network}"]
  location            = var.resource_group_location
  name                = "Emu-${each.value.short_name}-Net"
  resource_group_name = azurerm_resource_group.sh.name
  depends_on = [
    azurerm_resource_group.sh
  ]
}

# Create a subnet for all VMs
resource "azurerm_subnet" "subnet" {
  for_each             = var.customers
  address_prefixes     = ["${each.value.subnet}"]
  name                 = "default"
  resource_group_name  = azurerm_resource_group.sh.name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Create an AVD host pool for each customer
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  for_each                 = var.customers
  custom_rdp_properties    = "drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;enablerdsaadauth:i:1;targetisaadjoined:i:1;"
  description              = "${each.value.long_name} Host Pool created by Terraform"
  friendly_name            = each.value.long_name
  load_balancer_type       = "BreadthFirst"
  location                 = azurerm_resource_group.sh.location
  maximum_sessions_allowed = 5
  name                     = "${each.value.short_name}-HostPool"
  resource_group_name      = azurerm_resource_group.sh.name
  start_vm_on_connect      = true
  type                     = "Pooled"
  tags                     = each.value.tags
}

# Create AVD host pool registration info for each host pool
resource "azurerm_virtual_desktop_host_pool_registration_info" "hostpool-info" {
  for_each        = var.customers
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool[each.key].id
  expiration_date = timeadd(timestamp(), "24h")
}

# Create AVD Desktop Application Group for each customer
resource "azurerm_virtual_desktop_application_group" "dag" {
  for_each                     = var.customers
  default_desktop_display_name = "${each.value.long_name} Windows"
  description                  = "Desktop Application Group created by Terraform for ${each.value.long_name}"
  friendly_name                = "${each.value.long_name} Desktop"
  host_pool_id                 = azurerm_virtual_desktop_host_pool.hostpool[each.key].id
  location                     = azurerm_resource_group.sh.location
  name                         = "${each.value.short_name}-DAG"
  resource_group_name          = azurerm_resource_group.sh.name
  tags = {
    cm-resource-parent = azurerm_virtual_desktop_host_pool.hostpool[each.key].id
  }
  type = "Desktop"
  depends_on = [
    azurerm_virtual_desktop_host_pool.hostpool
  ]
}

# Create AVD workspace for each customer
resource "azurerm_virtual_desktop_workspace" "workspace" {
  for_each            = var.customers
  description         = "Workspace used for ${each.value.long_name}"
  friendly_name       = "${each.value.long_name} ws"
  location            = azurerm_resource_group.sh.location
  name                = "${each.value.short_name}-ws"
  resource_group_name = azurerm_resource_group.sh.name
  tags                = each.value.tags
}

# Associate Workspaces and DAGs
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  for_each             = var.customers
  application_group_id = azurerm_virtual_desktop_application_group.dag[each.key].id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace[each.key].id
  depends_on = [
    azurerm_virtual_desktop_application_group.dag,
    azurerm_virtual_desktop_workspace.workspace
  ]
}

#Create a virtual machine for each customer
resource "azurerm_windows_virtual_machine" "vm" {
  for_each       = var.customers
  admin_password = var.password
  admin_username = "LocalAdmin"
  license_type   = "Windows_Client"
  location       = azurerm_resource_group.sh.location
  name           = "EE-${each.value.short_name}-${random_string.chars.id}"
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]
  resource_group_name = azurerm_resource_group.sh.name
  secure_boot_enabled = true
  size                = "Standard_DS2_v2"
  tags = {
    cm-resource-parent = azurerm_virtual_desktop_host_pool.hostpool[each.key].id
  }
  vtpm_enabled = true
  zone         = 1
  additional_capabilities {
  }
  boot_diagnostics {
  }
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    offer     = "office-365"
    publisher = "microsoftwindowsdesktop"
    sku       = "win10-22h2-avd-m365-g2"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.nic
  ]
}

# Create a network interface for each VM
resource "azurerm_network_interface" "nic" {
  for_each            = var.customers
  location            = azurerm_resource_group.sh.location
  name                = "${each.value.short_name}-NIC"
  resource_group_name = azurerm_resource_group.sh.name
  tags = {
    cm-resource-parent = azurerm_virtual_desktop_host_pool.hostpool[each.key].id
  }
  ip_configuration {
    name                          = "ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet[each.key].id
  }
  depends_on = [
    azurerm_subnet.subnet
  ]
}

#Enable AAD Login for each VM
resource "azurerm_virtual_machine_extension" "vmext_aadlogin" {
  for_each             = var.customers
  auto_upgrade_minor_version = true
  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[each.key].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "2.0"
  depends_on = [ azurerm_windows_virtual_machine.vm ]
}

#Enable DSC for each VM
resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  for_each                   = var.customers
  auto_upgrade_minor_version = true
  name                       = "Microsoft.PowerShell.DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  settings                   = <<-SETTINGS
    {
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02507.246.zip",
      "properties": {
        "UseAgentDownloadEndpoint":true,
        "aadJoin":true,
        "aadJoinPreview":false,
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.hostpool[each.key].name}"
      }
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "properties": {
        "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.hostpool-info[each.key].token}"
      }
    }
  PROTECTED_SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
}

#Enable Azure Policy for each VM
#TODO: remove this?
resource "azurerm_virtual_machine_extension" "azure_policy" {
  for_each                   = var.customers
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  name                       = "AzurePolicyforWindows"
  publisher                  = "Microsoft.GuestConfiguration"
  type                       = "ConfigurationforWindows"
  type_handler_version       = "1.1"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[each.key].id
  depends_on                 = [azurerm_windows_virtual_machine.vm]
}