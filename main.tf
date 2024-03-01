data "azurerm_resource_group" "rg" {
  name                = var.rg
}

data "azurerm_ssh_public_key" "ssh_key" {
  name                = var.ssh_priv_key
  resource_group_name = var.rg
}

data "azurerm_virtual_network" "aap_network" {
  name                = var.virtual_network_name
  resource_group_name = var.rg
}

data "azurerm_subnet" "aap_subnet" {
  name                = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.aap_network.name
  resource_group_name = var.rg
}

# Create Network Security Group and rule
data "azurerm_network_security_group" "aap_nsg" {
  name                = var.nsg_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Create public IPs
resource "azurerm_public_ip" "aap_public_ip" {
  name                = var.public_ip_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  lifecycle {
    create_before_destroy = true
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = var.nic_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = var.nic_config_name
    subnet_id                     = data.azurerm_subnet.aap_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.aap_public_ip.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "aap_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = data.azurerm_network_security_group.aap_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = join("-", ["AAP-Hub", local.current_time])
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  #size                  = "Standard_DS1_v2"
  #size                  = "Standard_A8_v2"
  size                  = "Standard_DS3_v2"

  os_disk {
    name                 = var.os_disk_name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 90
  }

  source_image_reference {
    publisher = "RedHat"
    offer = "RHEL"
    sku = "8-lvm-gen2"
    version   = "latest"
  }

  computer_name  = join("-", ["AAP-Hub", local.current_time])

  admin_username = var.sshuser

  admin_ssh_key {
    username   = var.sshuser
    public_key = data.azurerm_ssh_public_key.ssh_key.public_key
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }

  user_data = base64encode(templatefile("${var.user_data}", {
    timezone             = var.timezone
    sshuser              = var.sshuser
    username             = var.redhat_login_user
    password             = var.redhat_login_pw
    ssh_priv_key         = var.ssh_priv_key
    #controller           = length(var.controller) != 0 ? join(" ", var.controller) : ""
    #automationcontroller = length(var.automationcontroller) != 0 ? join(" ", var.automationcontroller) : ""
    #hubinstance          = length(var.hubinstance) != 0 ? join(" ", var.hubinstance) : ""
    #dbinstance           = length(var.dbinstance) != 0 ? var.dbinstance : ""
    install_pkg          = var.install_pkg
    install_pkg_dest     = var.install_pkg_dest
  }))

  provisioner "file" {
    source      = var.ssh_priv_key
    destination = join("/", ["/home", var.sshuser, "/.ssh", var.ssh_priv_key])
    #destination = join("/", ["/tmp", var.ssh_priv_key])

    connection {
      type        = "ssh"
      user        = var.sshuser
      private_key = file("${path.module}/${var.ssh_priv_key}")
      host        = "${self.public_ip_address}"
    }
  }

  #provisioner "file" {
  #  source      = join("/", [var.install_pkg_path, var.install_pkg])
  #  destination = join("/", [var.install_pkg_dest, var.install_pkg])
  #
  #  connection {
  #    type        = "ssh"
  #    user        = var.sshuser
  #    private_key = file("${path.module}/${var.ssh_priv_key}")
  #    host        = "${self.public_ip_address}"
  #  }
  #}

}
