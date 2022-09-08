resource "databricks_group" "mlops-service-principal-group-staging" {
  display_name = "yang-mlops-project-service-principals"
  provider     = databricks.staging
}

resource "databricks_group" "mlops-service-principal-group-prod" {
  display_name = "yang-mlops-project-service-principals"
  provider     = databricks.prod
}

module "azure_create_sp" {
  depends_on = [databricks_group.mlops-service-principal-group-staging, databricks_group.mlops-service-principal-group-prod]
  source     = "databricks/mlops-azure-project-with-sp-creation/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod    = databricks.prod
    azuread            = azuread
  }
  service_principal_name       = "yang-mlops-project-cicd"
  project_directory_path       = "/yang-mlops-project"
  azure_tenant_id              = var.azure_tenant_id
  service_principal_group_name = "yang-mlops-project-service-principals"
}

data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

provider "databricks" {
  alias = "staging_sp"
  host  = "https://adb-8405830731420074.14.azuredatabricks.net"
  token = module.azure_create_sp.staging_service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = "https://adb-1005182519515014.14.azuredatabricks.net"
  token = module.azure_create_sp.prod_service_principal_aad_token
}


module "staging_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.staging_sp
  }
  git_provider    = var.git_provider
  git_token       = var.git_token
  github_repo_url = var.github_repo_url
  env             = "staging"
}

module "prod_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.prod_sp
  }
  git_provider    = var.git_provider
  git_token       = var.git_token
  github_repo_url = var.github_repo_url
  env             = "prod"
}

// We produce the service princpal's application ID, client secret, and tenant ID as output, to enable
// extracting their values and storing them as secrets in your CI system
//
// If using GitHub Actions, you can create new repo secrets through Terraform as well
// e.g. using https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret
output "STAGING_AZURE_SP_APPLICATION_ID" {
  value     = module.azure_create_sp.staging_service_principal_application_id
  sensitive = true
}

output "STAGING_AZURE_SP_CLIENT_SECRET" {
  value     = module.azure_create_sp.staging_service_principal_client_secret
  sensitive = true
}

output "STAGING_AZURE_SP_TENANT_ID" {
  value     = var.azure_tenant_id
  sensitive = true
}

output "PROD_AZURE_SP_APPLICATION_ID" {
  value     = module.azure_create_sp.prod_service_principal_application_id
  sensitive = true
}

output "PROD_AZURE_SP_CLIENT_SECRET" {
  value     = module.azure_create_sp.prod_service_principal_client_secret
  sensitive = true
}

output "PROD_AZURE_SP_TENANT_ID" {
  value     = var.azure_tenant_id
  sensitive = true
}
