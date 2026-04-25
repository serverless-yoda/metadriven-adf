variable "environment" {
  type        = string
  description = "The environment for deployment (dev, uat, prod)."
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be dev, uat, or prod."
  }
}

variable "suffix" {
  type        = string
  description = "A 3-letter suffix for resource uniqueness."
  validation {
    condition     = length(var.suffix) == 3
    error_message = "Suffix must be exactly 3 characters."
  }
}

variable "location" {
  type    = string
  default = "Australia East"
}

variable "sql_password" {
  type = string
  sensitive = true
}

variable "sql_administrator_login" {
  type    = string
  default = "sqladmin"
}

# FinOps: Mapping SKUs to Environments
locals {
  sql_sku = {
    dev  = "S0"
    uat  = "S1"
    prod = "P1"
  }
}

