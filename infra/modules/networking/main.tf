# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = var.tags
}

# Subnets
resource "azurerm_subnet" "apim" {
  name                 = "snet-apim-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.apim_subnet_address_prefix]

  # Required for APIM
  service_endpoints = ["Microsoft.Storage", "Microsoft.Sql", "Microsoft.EventHub"]
}

resource "azurerm_subnet" "functions_pe" {
  name                 = "snet-func-pe-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.functions_pe_subnet_address_prefix]

  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "webapp_integration" {
  name                 = "snet-webapp-int-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.webapp_integration_subnet_address_prefix]

  # Required for VNet integration
  delegation {
    name = "webapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Storage", "Microsoft.Web"]
}

resource "azurerm_subnet" "storage_pe" {
  name                 = "snet-storage-pe-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.storage_pe_subnet_address_prefix]

  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

# Network Security Groups (Optional but recommended)
resource "azurerm_network_security_group" "apim" {
  count               = var.enable_nsgs ? 1 : 0
  name                = "nsg-apim-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow inbound HTTPS from VNet
  security_rule {
    name                       = "AllowHTTPSFromVNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow APIM management endpoint
  security_rule {
    name                       = "AllowAPIMManagement"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "functions_pe" {
  count               = var.enable_nsgs ? 1 : 0
  name                = "nsg-func-pe-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow inbound HTTPS from APIM subnet
  security_rule {
    name                       = "AllowHTTPSFromAPIM"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.apim_subnet_address_prefix
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# NSG - Subnet associations
resource "azurerm_subnet_network_security_group_association" "apim" {
  count                     = var.enable_nsgs ? 1 : 0
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim[0].id
}

resource "azurerm_subnet_network_security_group_association" "functions_pe" {
  count                     = var.enable_nsgs ? 1 : 0
  subnet_id                 = azurerm_subnet.functions_pe.id
  network_security_group_id = azurerm_network_security_group.functions_pe[0].id
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "azurewebsites" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# VNet Links for Private DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "azurewebsites" {
  name                  = "vnetlink-azurewebsites-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azurewebsites.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "vnetlink-blob-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "vnetlink-file-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "vnetlink-queue-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "vnetlink-table-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = var.tags
}
