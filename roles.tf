data "azurerm_role_definition" "roleDVU" { # access an existing built-in role
  name = "Desktop Virtualization User"
}

data "azurerm_role_definition" "roleVMUL" { # access an existing built-in role
  name = "Virtual Machine User Login"
}

resource "azuread_group" "aad_group" {
  for_each         = var.customers
  display_name     = "demo-emu-${each.value.short_name}-AVD"
  security_enabled = true
}

resource "azurerm_role_assignment" "role" {
  for_each           = var.customers
  scope              = azurerm_virtual_desktop_application_group.dag[each.key].id
  role_definition_id = data.azurerm_role_definition.roleDVU.id
  principal_id       = azuread_group.aad_group[each.key].id
}

#Create virtual desktop administrators group
resource "azuread_group" "aad_group_admin" {
  display_name     = "emu-avd-admins"
  security_enabled = true
}

resource "azurerm_role_assignment" "role_VMUL" {
  for_each           = var.customers
  scope              = azurerm_resource_group.sh.id
  role_definition_id = data.azurerm_role_definition.roleVMUL.id
  principal_id       = azuread_group.aad_group[each.key].id
}

data "azuread_user" "aad_admins_list" {
  for_each            = toset(var.avd_admins)
  user_principal_name = format("%s", each.key)
}

#Add users to the admin group by email address
resource "azuread_group_member" "aad_avd_admins" {
  for_each         = data.azuread_user.aad_admins_list
  group_object_id  = azuread_group.aad_group_admin.id
  member_object_id = each.value["id"]
}

/* data "azuread_user" "aad_users_list" {
  for_each            = toset(var.avd_users)
  user_principal_name = format("%s", each.key)
}

#Add users to the customer groups by email address
resource "azuread_group_member" "aad_avd_users" {
  for_each         = data.azuread_user.aad_users_list
  group_object_id  = azuread_group.aad_group[each.key].id
  member_object_id = each.value["id"]
} */