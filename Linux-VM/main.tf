locals {
  resource_group_name = "Resurce-For-LinuxVM"
  location= "Japan East"
}

# Resource group
resource "azurerm_resource_group" "azrs" {
  name     = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "vn-linux" {
  name                = var.vn_name
  address_space       = [var.vn_address]
  location            = azurerm_resource_group.azrs.location
  resource_group_name = azurerm_resource_group.azrs.name
  
  tags = {
    environment= var.env
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet-name
  resource_group_name  = azurerm_resource_group.azrs.location
  virtual_network_name = azurerm_virtual_network.vn-linux.name
  address_prefixes     = [var.subnet_address]
}
#network security
resource "azurerm_network_security_group" "network-sg" {
  name                = var.nsg-name
  location            = azurerm_resource_group.azrs.location
  resource_group_name = azurerm_resource_group.azrs.name

  security_rule {
    name                       = "sgrule-for-linux"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.env
  }
}
#network association
resource "azurerm_subnet_network_security_group_association" "security-association" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.network-sg.id
}

resource "azurerm_public_ip" "public-add" {
  name                = "public_ip"
  resource_group_name = azurerm_resource_group.azrs.name
  location            = azurerm_resource_group.azrs.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.azrs.location
  resource_group_name = azurerm_resource_group.azrs.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public-add.id 
  }
  tags = {
    environment= var.env
  }
}

#generate SSH keys 
resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# create a file in current directory
resource "local_file" "linux_file" {
    filename = "linuxkey.pem"
    content     = tls_private_key.linux_key.private_key_pem
}

resource "azurerm_linux_virtual_machine" "vm-for-linux" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.azrs.name
  location            = azurerm_resource_group.azrs.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.linux_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-lts"
    version   = "latest"
  }

  depends_on = [
    tls_private_key.linux_key
  ]
}