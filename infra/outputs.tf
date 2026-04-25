output "adf_managed_identity_id" {
  value = azurerm_data_factory.adf.identity[0].principal_id
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "storage_account_name" {
  value = azurerm_storage_account.adls.name
}