resource "azurerm_resource_group" "app-grp-sod" {
  location = "East US"
  name     = "app-grp-sod"
}

resource "azurerm_network_security_group" "sg-sod" {
  name                = "security-group-SOD"
  location            = azurerm_resource_group.app-grp-sod.location
  resource_group_name = azurerm_resource_group.app-grp-sod.name
   security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "0.0.0.0/0"
     destination_address_prefix = "*"
  }
   security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "181.135.45.209"
     destination_address_prefix = "*"
  }


}

resource "azurerm_virtual_network" "sod-network" {
  name                = "sod-network"
  location            = azurerm_resource_group.app-grp-sod.location
  resource_group_name = azurerm_resource_group.app-grp-sod.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev-sod"
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.app-grp-sod.name
  virtual_network_name = azurerm_virtual_network.sod-network.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.app-grp-sod.name
  virtual_network_name = azurerm_virtual_network.sod-network.name
  address_prefixes     = ["10.0.2.0/24"]

}

resource "azurerm_subnet_network_security_group_association" "association1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.sg-sod.id
}

resource "azurerm_subnet_network_security_group_association" "association2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.sg-sod.id
}

resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.app-grp-sod.name
  location            = azurerm_resource_group.app-grp-sod.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic-sod" {
  name                = "nic-sod"
  location            = azurerm_resource_group.app-grp-sod.location
  resource_group_name = azurerm_resource_group.app-grp-sod.name

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}


resource "azurerm_linux_virtual_machine" "vm-sod" {
  name                = "vm-sod"
  resource_group_name = azurerm_resource_group.app-grp-sod.name
  location            = azurerm_resource_group.app-grp-sod.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  custom_data    = base64encode(data.template_file.linux-vm.rendered)
  network_interface_ids = [
    azurerm_network_interface.nic-sod.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

data "template_file" "linux-vm" {
  template = file("script.sh")
}
