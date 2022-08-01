
data "template_file" "linux_script" {
  template = file("${path.module}/scripts/install_runner.sh")
  vars = {
    github_org    = var.github_org_name
    runner_token  = var.github_runner_token
    runner_name   = var.github_runner_name
    runner_group  = "default"
    runner_labels = lower(join(",", var.runner_labels))
  }
}

resource "azurerm_network_interface" "internal_ni" {
  name                = "${var.names.product_group}-runner"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "runner"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "runner" {
  name                            = "${var.names.product_name}-runner"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_B2s"
  disable_password_authentication = true
  admin_username                  = var.username

  network_interface_ids = [
    azurerm_network_interface.internal_ni.id
  ]

  admin_ssh_key {
    username   = var.username
    public_key = var.public_key
  }

  custom_data = base64encode(data.template_file.linux_script.rendered)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}