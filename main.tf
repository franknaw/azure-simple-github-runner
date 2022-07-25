
data "template_file" "linux_script" {
  template = file("${path.module}/scripts/startup.sh")
  vars = {
    github_repo   = var.github_repo_name
    github_org    = var.github_org_name
    runner_token  = "AJJHA2R6G23J2B2MV2TTTPDC3MLAM" #var.github_runner_token
    runner_name   = var.name
    runner_group  = var.runner_group
    runner_labels = lower(join(",", var.runner_labels))
    runner_scope  = lower(var.runner_scope)
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.runner_os == "linux" ? 1 : 0
  name                            = "${var.name}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tags                            = var.tags
  size                            = var.virtual_machine_size
  admin_username                  = var.username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.internal_ni.id]
  source_image_id                 = var.custom_ubuntu_image_id

  admin_ssh_key {
    username   = var.username
    public_key = var.public_key
  }

  # dynamic "boot_diagnostics" {
  #   for_each = var.enable_boot_diagnostics ? ["enabled"] : []
  #   content {
  #     # storage_account_uri = var.diagnostics_storage_account_uri
  #     storage_account_uri = module.storage_account.primary_blob_endpoint

  #   }
  # }

  custom_data = base64encode(data.template_file.linux_script.rendered)

  dynamic "source_image_reference" {
    for_each = var.custom_ubuntu_image_id == null ? ["no-custom-image"] : []

    content {
      publisher = var.ubuntu_source_image_reference.publisher
      offer     = var.ubuntu_source_image_reference.offer
      sku       = var.ubuntu_source_image_reference.sku
      version   = var.ubuntu_source_image_reference.version
    }
  }

  os_disk {
    caching                   = "ReadWrite"
    storage_account_type      = "StandardSSD_LRS"
    write_accelerator_enabled = false
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_ids
  }
}

resource "azurerm_network_interface" "internal_ni" {
  name                = "${var.name}-ni"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# resource "azurerm_network_security_rule" "bastion_sr" {
#   name                        = "bastion-sr"
#   priority                    = 101
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefixes     = values(var.source_address_prefixes)
#   #destination_address_prefix  = azurerm_network_interface.bastion.private_ip_address
#   destination_address_prefix = var.destination_address_prefix
  
#   resource_group_name         = var.resource_group_name
#   network_security_group_name = azurerm_network_security_group.nsg.name
#   depends_on                  = [azurerm_network_security_group.nsg]
# }


# resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {

#   subnet_id                 = var.subnet_id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }

# resource "azurerm_network_security_group" "nsg" {

#   name                = "${var.names.resource_group_type}-${var.names.product_name}-security-group"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   tags                = merge(var.tags, {foo = "foo"})
# }

# module "storage_account" {
#   source                    = "git::https://github.com/Azure-Terraform/terraform-azurerm-storage-account.git?ref=v0.12.1"
#   resource_group_name       = var.resource_group_name
#   location                  = var.location
#   tags                      = var.tags
#   account_kind              = "StorageV2"
#   replication_type          = "LRS"
#   account_tier              = "Standard"
#   default_network_rule      = "Allow"
#   shared_access_key_enabled = true
#   traffic_bypass            = ["AzureServices", "Logging"]
#   service_endpoints = {
#     "iaas-outbound" = var.subnet_id
#   }
# }
