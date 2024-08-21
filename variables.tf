variable "customers" {
  type = map(object({
    short_name = string,
    long_name  = string,
    network    = string,
    subnet     = string,
    tags       = map(string)
  }))
  default = {
    c1 = {
      short_name = "Cust1"
      long_name  = "Customer One"
      network    = "10.100.0.0/16"
      subnet     = "10.100.0.0/24"
      tags = {
        "customer"    = "cust1"
        "environment" = "dev"
      },
    },
    # c2 = {
    #   short_name = "Cust2"
    #   long_name  = "Customer Two"
    #   network    = "10.101.0.0/16"
    #   subnet     = "10.101.0.0/24"
    #   tags = {
    #     "customer"    = "cust2"
    #     "environment" = "dev"
    #   },
    # },
    # c3 = {
    #   short_name = "Cust3"
    #   long_name  = "Customer Three"
    #   network    = "10.102.0.0/16"
    #   subnet     = "10.102.0.0/24"
    #   tags = {
    #     "customer"    = "cust3"
    #     "environment" = "dev"
    #   },
    # },
  }
}

variable "resource_group_location" {
  default     = "eastus2"
  description = "Location of the resource group."
}

variable "azure_machine_size" {
  default     = "Standard_DS1_v2"
  description = <<EOT
    Size of the Azure Virtual Machine.  
    Please note, availability of sizes varies by subscription limits and region.  
    What works in one location might not work in another.  
    If you run into trouble, please check by creating a test VM manually.
  EOT
}

variable "machine_zone" {
  default     = 2
  description = "Availability zone for the virtual machine."
}

variable "admin_password" {
  type        = string
  description = <<EOT
    Password value taken from local machine env variable. 
    To apply the value in a linux environment, and assuming you are using VS code for IDE, use "export TF_VAR_admin_password=<EnterValueHere>"
  EOT
}

variable "admin_username" {
  default     = "LocalAdmin"
  type        = string
  description = "Virtual machine administrator username"
}

#Domain machine admins
variable "avd_admins" {
  description = "Azure Virtual Desktop Admins"
  default = [
    "jlaing@netglass.io"
  ]
}

variable "avd_users" {
  description = "Azure Virtual Desktop Users"
  default = [
    "jlaing@netglass.io"
  ]
}


