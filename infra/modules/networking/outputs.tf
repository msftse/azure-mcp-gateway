output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "apim_subnet_id" {
  description = "ID of the APIM subnet"
  value       = azurerm_subnet.apim.id
}

output "functions_pe_subnet_id" {
  description = "ID of the Functions private endpoint subnet"
  value       = azurerm_subnet.functions_pe.id
}

output "webapp_integration_subnet_id" {
  description = "ID of the Web App integration subnet"
  value       = azurerm_subnet.webapp_integration.id
}

output "storage_pe_subnet_id" {
  description = "ID of the Storage private endpoint subnet"
  value       = azurerm_subnet.storage_pe.id
}

output "private_dns_zone_azurewebsites_id" {
  description = "ID of the Azure Websites private DNS zone"
  value       = azurerm_private_dns_zone.azurewebsites.id
}

output "private_dns_zone_blob_id" {
  description = "ID of the Blob Storage private DNS zone"
  value       = azurerm_private_dns_zone.blob.id
}

output "private_dns_zone_file_id" {
  description = "ID of the File Storage private DNS zone"
  value       = azurerm_private_dns_zone.file.id
}

output "private_dns_zone_queue_id" {
  description = "ID of the Queue Storage private DNS zone"
  value       = azurerm_private_dns_zone.queue.id
}

output "private_dns_zone_table_id" {
  description = "ID of the Table Storage private DNS zone"
  value       = azurerm_private_dns_zone.table.id
}
