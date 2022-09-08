variable "git_token" {
  type        = string
  description = "Git token used to (1) checkout ML code to run during CI and (2) call back from Databricks -> GitHub Actions to trigger a model deployment CD workflow when automated model retraining completes. Must have read and write permissions on the Git repo containing the current ML project"
  sensitive   = true
}

variable "git_provider" {
  type        = string
  description = "Hosted Git provider, as described in https://docs.microsoft.com/azure/databricks/dev-tools/api/latest/gitcredentials#operation/create-git-credential. For example, 'gitHub' if using GitHub."
}

variable "github_repo_url" {
  type        = string
  description = "URL of the hosted git repo containing the current ML project, e.g. https://github.com/myorg/myrepo"
}

variable "env" {
  type        = string
  description = "Current env, i.e. 'staging' or 'prod'"
}
