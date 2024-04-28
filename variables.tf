variable "versionid" {
  default     = "00"
  description = "Versão do arquivo - usado como sulfixo dos nomes."
}

# Auth variables
variable "tenantid" {
  type     = string
  description = "Tenant code."
}

variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type     = string
  description = "Name to fix the Resource Group Name instead of a random one."
}

variable "workspace_name" {
  type     = string
  description = "Workspace name."
}

variable "appinsights_id" {
  type     = string
  description = "Application Insight ID."
}

variable "kvault_id" {
  type     = string
  description = "Key vault ID."
}

variable "saccount_id" {
  type     = string
  description = "Storage account ID."
}

variable "containerregitry_id" {
  type     = string
  description = "Container Regitry ID."
}