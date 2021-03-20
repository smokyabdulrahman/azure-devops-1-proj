provider "azurerm" {
  features {}
}

// Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

// Virtual Network & Subnet
resource "azurerm_virtual_network" "main" {
  resource_group_name = azurerm_resource_group.main.name
  name                = "${var.prefix}-vn"
  location            = azurerm_resource_group.main.location
  tags                = azurerm_resource_group.main.tags
  address_space       = ["${var.vn_address_space}"]
}

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["${var.vn_address_space}"]
}

// Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = azurerm_resource_group.main.tags

  security_rule {
    name                       = "DenyInternetToVN"
    description                = "Deny internet access To VMs"
    direction                  = "Inbound"
    priority                   = 4096
    protocol                   = "*"
    access                     = "Deny"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_range     = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowCommunicationInVN"
    description                = "Allow VMs to communicate within the virtual network"
    direction                  = "Outbound"
    priority                   = 100
    protocol                   = "*"
    access                     = "Allow"
    source_port_range          = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_port_range     = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  #   {
  #     name                       = "Deny Internet Access From Virtual Network"
  #     description                = "Deny internet access from VMs"
  #     direction                  = "Inbound"
  #     priority                   = 4096
  #     protocol                   = "*"
  #     access                     = "Deny"
  #     source_port_range          = "*"
  #     source_address_prefix      = "VirtualNetwork"
  #     destination_port_range     = "*"
  #     destination_address_prefix = "Internet"
  #     }, 
}

// Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = azurerm_resource_group.main.tags
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

// Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = azurerm_resource_group.main.tags
  allocation_method   = "Static"
}

// LoadBalancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = azurerm_resource_group.main.tags

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-be-ap"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  ip_configuration_name   = "internal"
  network_interface_id    = azurerm_network_interface.main.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# resource "azurerm_lb_probe" "main" {
#   resource_group_name = azurerm_resource_group.main.name
#   loadbalancer_id     = azurerm_lb.main.id
#   name                = "ssh-running-probe"
#   port                = var.application_port
# }

# resource "azurerm_lb_rule" "main" {
#   resource_group_name            = azurerm_resource_group.main.name
#   loadbalancer_id                = azurerm_lb.main.id
#   name                           = "http"
#   protocol                       = "Tcp"
#   frontend_port                  = var.application_port
#   backend_port                   = var.application_port
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
#   frontend_ip_configuration_name = "PublicIPAddress"
#   probe_id                       = azurerm_lb_probe.main.id
# }

// VM Availability Set
resource "azurerm_availability_set" "main" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tags                        = azurerm_resource_group.main.tags
  platform_fault_domain_count = 2
}

// VMs
data "azurerm_resource_group" "image" {
  name = var.image_rg
}

data "azurerm_image" "image" {
  name                = var.image_name
  resource_group_name = data.azurerm_resource_group.image.name
}

resource "azurerm_virtual_machine" "main" {
  count                 = var.vm_replicas
  name                  = "${var.prefix}${count.index}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  availability_set_id   = azurerm_availability_set.main.id
  vm_size               = var.vm_size

  storage_image_reference {
    id = data.azurerm_image.image.id
  }

  storage_os_disk {
    name          = "${var.prefix}${count.index}-os-disk"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = var.ssh_username
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/id_rsa.pub")
      path     = "/home/${var.ssh_username}/.ssh/authorized_keys"
    }
  }
}

// Managed Disks for VMs
resource "azurerm_managed_disk" "main" {
  count                = var.vm_replicas
  name                 = "${var.prefix}${count.index}-disk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  create_option        = "Empty"
  disk_size_gb         = 30
  tags                 = azurerm_resource_group.main.tags
  storage_account_type = "Standard_LRS"
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.vm_replicas
  managed_disk_id    = azurerm_managed_disk.main.*.id[count.index]
  virtual_machine_id = azurerm_virtual_machine.main.*.id[count.index]
  lun                = count.index + 10
  caching            = "ReadWrite"
}
