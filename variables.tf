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
      network    = "13.251.0.0/16"
      subnet     = "13.251.0.0/24"
      tags = {
        "customer"    = "cust1"
        "environment" = "dev"
      },
    },
    c2 = {
      short_name = "Cust2"
      long_name  = "Customer Two"
      network    = "13.252.0.0/16"
      subnet     = "13.252.0.0/24"
      tags = {
        "customer"    = "cust2"
        "environment" = "dev"
      },
    },
    c3 = {
      short_name = "Cust3"
      long_name  = "Customer Three"
      network    = "13.253.0.0/16"
      subnet     = "13.253.0.0/24"
      tags = {
        "customer"    = "cust3"
        "environment" = "dev"
      },
    },
  }
}

variable "resource_group_location" {
  default     = "westus3"
  description = "Location of the resource group."
}

variable "password" {
  type        = string
  description = "Password value taken from local machine env variable. To apply the value in linux, and assuming you are using VS code for IDE, use \"export TF_VAR_password=+EnterValueHere+\""
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


