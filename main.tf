terraform {
  required_version = ">=1.8.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.42"
    }
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  tenant_id         = var.tenantid
  features {}
}

provider "azapi" {}

data "azurerm_client_config" "current" {}


resource "azurerm_monitor_action_group" "aabeck01" {
  name                = "Application Insights Smart Detection"
  resource_group_name = var.resource_group_name
  short_name          = "SmartDetect"

  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }
  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }
}


resource "azurerm_application_insights" "aabeck01" {
  name                = var.appinsights_id
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  application_type    = "web"

  tags = {
    Environment = "development"
  }
}


resource "azurerm_user_assigned_identity" "aabeck01" {
  name                = "aabeck-identity"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}


resource "azurerm_key_vault" "aabeck01" {
  name                = var.kvault_id
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  public_network_access_enabled = true

  tags = {
    Environment = "development"
  }
}


resource "azurerm_key_vault_access_policy" "aabeck01-identity" {
  key_vault_id = azurerm_key_vault.aabeck01.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.aabeck01.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
    "Create",
    "Recover",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

resource "azurerm_key_vault_access_policy" "aabeck01-tenant" {
  key_vault_id = azurerm_key_vault.aabeck01.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Create",
    "Recover",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]
}


resource "azurerm_storage_account" "aabeck01" {
  name                     = var.saccount_id
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "GRS"
  public_network_access_enabled = true

  tags = {
    Environment = "development"
  }
}


resource "azurerm_container_registry" "aabeck01" {
  name                = var.containerregitry_id
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Premium"
  admin_enabled       = true

  tags = {
    Environment = "development"
  }
}


resource "azurerm_role_assignment" "aabeck01-role1" {
  scope                = azurerm_key_vault.aabeck01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}

resource "azurerm_role_assignment" "aabeck01-role2" {
  scope                = azurerm_key_vault.aabeck01.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}

resource "azurerm_role_assignment" "aabeck01-role3" {
  scope                = azurerm_storage_account.aabeck01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}

resource "azurerm_role_assignment" "aabeck01-role4" {
  scope                = azurerm_storage_account.aabeck01.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}

resource "azurerm_role_assignment" "aabeck01-role5" {
  scope                = azurerm_application_insights.aabeck01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}

resource "azurerm_role_assignment" "aabeck01-role6" {
  scope                = azurerm_container_registry.aabeck01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}

resource "azurerm_role_assignment" "aabeck01-role7" {
  scope                = azurerm_monitor_action_group.aabeck01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.aabeck01.principal_id
}


resource "azurerm_machine_learning_workspace" "aabeck01" {
  name                          = var.workspace_name
  location                      = var.resource_group_location
  resource_group_name           = var.resource_group_name
  application_insights_id       = azurerm_application_insights.aabeck01.id
  key_vault_id                  = azurerm_key_vault.aabeck01.id
  storage_account_id            = azurerm_storage_account.aabeck01.id
  container_registry_id         = azurerm_container_registry.aabeck01.id
  public_network_access_enabled = true

  primary_user_assigned_identity = azurerm_user_assigned_identity.aabeck01.id
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aabeck01.id,
    ]
  }

  depends_on = [
    azurerm_role_assignment.aabeck01-role1,
    azurerm_role_assignment.aabeck01-role2,
    azurerm_role_assignment.aabeck01-role3,
    azurerm_role_assignment.aabeck01-role4,
    azurerm_role_assignment.aabeck01-role5,
    azurerm_role_assignment.aabeck01-role6,
    azurerm_role_assignment.aabeck01-role7,
  ]

  tags = {
    Environment = "development"
  }
}



/*
resource "null_resource" "createdestroyfile" {
  provisioner "local-exec" {
    command = "terraform plan -destroy -out main.destroy.tfplan"
    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [
    azurerm_machine_learning_workspace.aabeck01,
  ]
}
*/
/*
    terraform plan -out main.tfplan
    terraform plan -destroy -out main.destroy.tfplan

    terraform apply main.tfplan
    terraform apply main.destroy.tfplan

    terraform output -raw tls_private_key > ..\auth_fs\infra.pka
    terraform output public_ip_address

    ssh -i ..\auth_fs\infra.pka beck_alvaro@<ip_address>
*/