
output "private_ip" {
  description = "Virtual network data object."
  value       = azurerm_network_interface.internal_ni.private_ip_address
}
