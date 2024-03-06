locals {
    current_time = formatdate("YYMMDDhhmm", timestamp())
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

variable "execinstance" {
  type        = string
  default     = ""
}

variable "hubinstance" {
  type        = string
  default     = ""
}

variable "hub_size" {
  type    = string
  default = "Standard_DS3_v2"
}

variable "hub_name" {
  type    = string
  default = "AAP-Hub"
}

variable "hub_os_disk_sz" {
  type    = number
  default = 100
}

variable "hub_filesystems" {
  description = "non-default filesystems in the form of LV_name=lvsize(in Gb):mount point"
  type = map(string)
  default = {
    varlv = "40G:/var"
    tmplv = "10G:/tmp"
    awxlv = "20G:/var/lib/awx"
  }
}
