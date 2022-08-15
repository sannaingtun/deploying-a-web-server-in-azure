provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
   count               = var.vm_count
   name                = "acctni${count.index}"
   location            = azurerm_resource_group.main.location
   resource_group_name = azurerm_resource_group.main.name

   ip_configuration {
     name                          = "internal"
     subnet_id                     = azurerm_subnet.internal.id
     private_ip_address_allocation = "Dynamic"
   }

  tags = var.tags
 }

resource "azurerm_network_security_group" "main" {
  name                = "nsg-for-project1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

// The NSG rules are missing. Please add a rule to DENY all Inbound traffic.
resource "azurerm_network_security_rule" "rule_deny_all_inbound" {
  name                          = "deny-all-inbound"
  priority                      = 100
  direction                     = "Inbound"
  access                        = "Deny"
  protocol                      = "Tcp"
  source_port_range             = "*"
  destination_port_range        = "*"
  source_address_prefix         = "Internet"
  destination_address_prefixes  = ["10.0.2.0/24"]
  resource_group_name           = azurerm_resource_group.main.name
  network_security_group_name   = azurerm_network_security_group.main.name
  description                   = "Deny all inbound traffic"
}

 resource "azurerm_network_interface_security_group_association" "main" {
  count = length(azurerm_network_interface.main)
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = length(azurerm_network_interface.main)
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bpepool.id
}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "azurerm_public_ip" "main" {
  name                = "vm-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  domain_name_label   = "${random_string.fqdn.result}-ssh"
  tags                = var.tags
}

resource "azurerm_lb" "main" {
  name                = "vmss-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.main.id
}

resource "azurerm_managed_disk" "main" {
   count                = 2
   name                 = "datadisk_existing_${count.index}"
   location             = azurerm_resource_group.main.location
   resource_group_name  = azurerm_resource_group.main.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = "1023"
   tags                         = var.tags
 }

 resource "azurerm_availability_set" "avset" {
   name                         = "avset"
   location                     = azurerm_resource_group.main.location
   resource_group_name          = azurerm_resource_group.main.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
   tags                         = var.tags
 }

 resource "azurerm_virtual_machine" "main" {
   count                 = var.vm_count
   name                  = "acctvm${count.index}"
   location              = azurerm_resource_group.main.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.main.name
   network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
   vm_size               = "Standard_DS1_v2"

   # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

   storage_image_reference {
    id = data.azurerm_image.image.id
  }

   storage_os_disk {
     name              = "myosdisk${count.index}"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
   }

   # Optional data disks
   storage_data_disk {
     name              = "datadisk_new_${count.index}"
     managed_disk_type = "Standard_LRS"
     create_option     = "Empty"
     lun               = 0
     disk_size_gb      = "1023"
   }

   storage_data_disk {
     name            = element(azurerm_managed_disk.main.*.name, count.index)
     managed_disk_id = element(azurerm_managed_disk.main.*.id, count.index)
     create_option   = "Attach"
     lun             = 1
     disk_size_gb    = element(azurerm_managed_disk.main.*.disk_size_gb, count.index)
   }

   os_profile {
     computer_name  = "hostname"
     admin_username = var.admin_user
     admin_password = var.admin_password
   }

   os_profile_linux_config {
     disable_password_authentication = false
   }

   tags = var.tags
 }
