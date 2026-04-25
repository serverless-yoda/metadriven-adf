provider "azurerm" {
  features {}
}

# Requirement: Dynamically fetch current public IP for SQL Firewall
# Use an IPv4-only endpoint to prevent IPv6 errors
data "http" "my_public_ip" {
  url = "https://api4.ipify.org" # This specifically forces IPv4
}

locals {
  env_name     = var.environment
  short_suffix = var.suffix
  # Requirement: rg_metadriven_{environment}_{3 letters suffix}
  resource_group_name = "rg_metadriven_${local.env_name}_${local.short_suffix}"
  # Requirement: metadriven{environment}{3 letters suffix}
  storage_name = "adlsmetadriven${local.env_name}${local.short_suffix}"
  # Generic suffix for other resources
  common_suffix = "${local.env_name}_${local.short_suffix}"
  adf_common_suffix = "${local.env_name}-${local.short_suffix}"
  my_ipv4 = chomp(data.http.my_public_ip.response_body)

  sql_password = var.sql_password
  sql_administrator_login = var.sql_administrator_login
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags = {
    Environment = local.env_name
    Project     = "MetadataDrivenOrchestration"
    FinOps      = "Auto-Pause-Enabled"
  }
}

# Requirement: Storage Account ADLS Gen2
resource "azurerm_storage_account" "adls" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Critical for Medallion Architecture

  network_rules {
    default_action = "Allow" # Adjusted for initial setup, usually restricted in Prod
    bypass         = ["AzureServices"]
  }
}

# ADLS Containers for Medallion Architecture
resource "azurerm_storage_data_lake_gen2_filesystem" "layers" {
  for_each           = toset(["bronze", "silver", "gold", "config"])
  name               = each.key
  storage_account_id = azurerm_storage_account.adls.id
}

# Azure SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = "sqlmetadriven${local.short_suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = local.sql_administrator_login
  administrator_login_password = local.sql_password # In Prod, use a random provider
}

# Requirement: SQL dynamic IP acceptance
resource "azurerm_mssql_firewall_rule" "allow_me" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = local.my_ipv4
  end_ip_address   = local.my_ipv4
}

# Azure SQL Database with FinOps SKU switching
# resource "azurerm_mssql_database" "db" {
#   name         = "db_metadriven_${local.common_suffix}"
#   server_id    = azurerm_mssql_server.sql.id
#   sku_name     = lookup(local.sql_sku, local.env_name)
#   max_size_gb  = 2
# }

# Azure SQL Database with AdventureWorks Sample & FinOps
resource "azurerm_mssql_database" "db" {
  name         = "db_metadriven_${local.common_suffix}"
  server_id    = azurerm_mssql_server.sql.id
  sku_name     = lookup(local.sql_sku, local.env_name)
  max_size_gb  = 2
  
  # Requirement: Load AdventureWorks as the default source
  # Note: This only works with 'General Purpose' or 'Basic/Standard' SKUs
  sample_name  = "AdventureWorksLT" 

  # FinOps standout: Auto-pause after 1 hour of inactivity (if using Serverless)
  # auto_pause_delay_in_minutes = 60 

  tags = {
    DataSource = "AdventureWorksLT"
    Env        = var.environment
  }
}
# Azure Data Factory with Managed VNet
resource "azurerm_data_factory" "adf" {
  name                            = "adf-metadriven-${local.adf_common_suffix}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  managed_virtual_network_enabled = true # Standing out with Security

  identity {
    type = "SystemAssigned" # Requirement: Managed Identity Auth
  }
}

# Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                = "kv-metadriven-${local.short_suffix}-${local.env_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

# Access Policy for ADF to read secrets (Zero-Trust)
resource "azurerm_key_vault_access_policy" "adf_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.adf.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

data "azurerm_client_config" "current" {}