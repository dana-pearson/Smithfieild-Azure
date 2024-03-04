locals {
    current_time = formatdate("YYMMDDhhmm", timestamp())
    user_data_vars = {
      timezone             = var.timezone
      sshuser              = var.sshuser
      username             = var.redhat_login_user
      password             = var.redhat_login_pw
      ssh_priv_key         = var.ssh_priv_key
      install_pkg          = var.install_pkg
      install_pkg_dest     = var.install_pkg_dest
      controller   = length(var.controller) != 0 ? join(" ", var.controller) : ""
      dbinstance   = length(var.dbinstance) != 0 ? join(" ", var.dbinstance) : ""
      hubinstance  = length(var.hubinstance) != 0 ? join(" ", var.hubinstance) : ""
    }

}

variable "timezone" {
  type    = string
  default = "US/Eastern"
}

variable "redhat_login_user" {
  type    = string
  default = "dana_pearson@stratascale.com"
  sensitive = true
}

variable "redhat_login_pw" {
  type    = string
  default = "M1dM@y!!"
  sensitive = true
  nullable = false
}

variable "install_pkg_path" {
  type    = string
  default = ".."
}

variable "install_pkg_dest" {
  type    = string
  default = "/var/tmp"
}

variable "install_pkg" {
  type    = string
  default = "ansible-automation-platform-setup-bundle-2.4-3-x86_64.tar.gz"
}

variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "CIS-Test"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "sshuser" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}

variable "rg" {
  type        = string
  description = "Existing Resource Group"
  default     = "CIS-Test"
}
 
variable "ssh_priv_key" {
  type        = string
  default     = "AAP_ssh_key"
}

variable "virtual_network_name" {
  type        = string
  default     = "aap_existing_network"
}

variable "subnet_name" {
  type        = string
  default     = "aap_existing_subnet"
}

variable "nsg_name" {
  type        = string
  default     = "aap_existing_nsg"
}

variable "public_ip_name" {
  type        = string
  default     = "aap_public_IP"
}

variable "nic_name" {
  type        = string
  default     = "aap_nic"
}

variable "nic_config_name" {
  type        = string
  default     = "aap_nic_configuration"
}

variable "aap_vm_name" {
  type        = string
  default     = "aap_vm"
}

variable "os_disk_name" {
  type        = string
  default     = "aap_os_disk"
}

variable "user_data" {
  type        = string
  default     = "user_data.sh"
}

variable "controller" {
  type        = string
  default     = ""
}

variable "dbinstance" {
  type        = string
  default     = ""
}

variable "hubinstance" {
  type        = string
  default     = ""
}

variable "hub_name" {
  type    = string
  default = "AAP-Hub"
}

variable "hub_filesystems" {
  type = map(number)
  default = {
    total  = 50
    varlv  = 40
    tmplv  = 10
  }
}
