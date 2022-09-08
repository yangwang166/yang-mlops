# MLOps Template Setup Scripts
This directory contains setup scripts intended to automate CI/CD and ML resource config setup
for MLOps engineers.

The scripts set up CI/CD with GitHub Actions. If using another CI/CD provider, you can
easily translate the provided CI/CD workflows (GitHub Actions YAML under `.github/workflows`)
to other CI/CD providers by running the same shell commands, with a few caveats:

* Usages of the `run-notebook` Action should be replaced by [installing the Databricks CLI](https://github.com/databricks/databricks-cli#installation)
  and invoking the `databricks runs submit --wait` CLI
  ([docs](https://docs.microsoft.com/azure/databricks/dev-tools/cli/runs-cli#submit-a-one-time-run)).
* The model deployment CD workflows in `deploy-model-prod.yml` and `deploy-model-staging.yml` are currently triggered
  by the `notebooks/TriggerModelDeploy.py` helper notebook after the model training job completes. This notebook
  hardcodes the API endpoint for triggering a GitHub Actions workflow. Update `notebooks/TriggerModelDeploy.py`
  to instead hit the appropriate REST API endpoint for triggering model deployment CD for your CI/CD provider.

## Prerequisites

### Install CLIs
* Install the [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* Install the [Databricks CLI](https://github.com/databricks/databricks-cli): ``pip install databricks-cli``
* Install Azure CLI: ``pip install azure-cli``


### Verify permissions
To use the scripts, you must:
* Be a Databricks workspace admin in the staging and prod workspaces. Verify that you're an admin by viewing the
  [staging workspace admin console](https://adb-8405830731420074.14.azuredatabricks.net#setting/accounts) and
  [prod workspace admin console](https://adb-1005182519515014.14.azuredatabricks.net#setting/accounts). If
  the admin console UI loads instead of the Databricks workspace homepage, you are an admin.
* Be able to create Git tokens with permission to check out the current repository
* Determine the Azure AAD tenant (directory) ID and subscription associated with your staging and prod workspaces,
  and verify that you have at least [Application.ReadWrite.All](https://docs.microsoft.com/en-us/graph/permissions-reference#application-resource-permissions) permissions on
  the AAD tenant and ["Contributor" permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all) on
  the subscription. To do this:
    1. Navigate to the [Azure Databricks resource page](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Databricks%2Fworkspaces) in the Azure portal. Ensure there are no filters configured in the UI, i.e. that
       you're viewing workspaces across all Subscriptions and Resource Groups.
    2. Search for your staging and prod workspaces by name to verify that they're part of the current directory. If you don't know the workspace names, you can log into the
       [staging workspace](https://adb-8405830731420074.14.azuredatabricks.net) and [prod workspace](https://adb-1005182519515014.14.azuredatabricks.net) and use the
       [workspace switcher](https://docs.microsoft.com/azure/databricks/workspace/#switch-to-a-different-workspace) to view
       the workspace name
    3. If you can't find the workspaces, switch to another directory by clicking your profile info in the top-right of the Azure Portal, then
       repeat steps i) and ii). If you still can't find the workspace, ask your Azure account admin to ensure that you have
       at least ["Contributor" permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all)
       on the subscription containing the workspaces. After confirming that the staging and prod workspaces are in the current directory, proceed to the next steps.
    4. The [Azure Databricks resource page](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Databricks%2Fworkspaces)
       contains links to the subscription containing your staging and prod workspaces. Click into the subscription, copy its ID ("Subscription ID"), and
       store it as an environment variable by running `export AZURE_SUBSCRIPTION_ID=<subscription-id>`
    5. Verify that you have "Contributor" access by clicking into
       "Access Control (IAM)" > "View my access" within the subscription UI,
       as described in [this doc page](https://docs.microsoft.com/en-us/azure/role-based-access-control/check-access#step-1-open-the-azure-resources).
       If you don't have [Contributor permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#all),
       ask an Azure account admin to grant access.
    6. Find the current tenant ID
       by navigating to [this page](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Properties),
       also accessible by navigating to the [Azure Active Directory UI](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Overview)
       and clicking Properties. Save the tenant ID as an environment variable by running `export AZURE_TENANT_ID=<id>`
    7. Verify that you can create and manage service principals in the AAD tenant, by opening the
       [App registrations UI](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
       under the Azure Active Directory resource within the Azure portal. Then, verify that you can click "New registration" to create
       a new AAD application, but don't actually create one. If unable to click "New registration", ask your Azure admin to grant you [Application.ReadWrite.All](https://docs.microsoft.com/en-us/graph/permissions-reference#application-resource-permissions) permissions
  

### Configure Azure auth
* Log into Azure via `az login --tenant "$AZURE_TENANT_ID"`
* Run `az account set --subscription "$AZURE_SUBSCRIPTION_ID"` to set the active Azure subscription


### Configure Databricks auth
* Configure a Databricks CLI profile for your staging workspace by running
  ``databricks configure --token --profile "yang-mlops-project-staging" --host https://adb-8405830731420074.14.azuredatabricks.net``, 
  which will prompt you for a REST API token
* Create a [Databricks REST API token](https://docs.microsoft.com/azure/databricks/dev-tools/api/latest/authentication#generate-a-personal-access-token)
  in the staging workspace ([link](https://adb-8405830731420074.14.azuredatabricks.net#setting/account))
  and paste the value into the prompt.
* Configure a Databricks CLI for your prod workspace by running ``databricks configure --token --profile "yang-mlops-project-prod" --host https://adb-1005182519515014.14.azuredatabricks.net``
* Create a Databricks REST API token in the prod workspace ([link](https://adb-1005182519515014.14.azuredatabricks.net#setting/account)).
  and paste the value into the prompt

### Obtain a git token for use in CI/CD
The setup script prompts a Git token with both read and write permissions
on the current repo.

This token is used to:
1. Fetch ML code from the current repo to run on Databricks for CI/CD (e.g. to check out code from a PR branch and run it
during CI/CD).
2. Call back from
   Databricks -> GitHub Actions to trigger a model deployment deployment workflow when
   automated model retraining completes, i.e. perform step (2) in
   [this diagram](https://github.com/databricks/mlops-project-template/blob/main/Pipeline.md#model-training-pipeline).

If using GitHub as your hosted Git provider, you can generate a Git token through the [token UI](https://github.com/settings/tokens/new);
be sure to generate a token with "Repo" scope.

## Usage

### Run the scripts
From the repo root directory, run:

```
python .mlops-setup-scripts/terraform/bootstrap.py
```

```
# Alternatively, run `python .mlops-setup-scripts/cicd/bootstrap.py`,
# which will prompt you for inputs
python .mlops-setup-scripts/cicd/bootstrap.py \
  --var azure_tenant_id="$AZURE_TENANT_ID" \
  --var git_provider=gitHub \
  --var github_repo_url=https://github.com/<your-org>/<your-repo-name> \
  --var git_token=<your-git-token>
```

Take care to run the Terraform bootstrap script before the CI/CD bootstrap script. This will:


1. Create an Azure Blob Storage container for storing ML resource config (job, MLflow experiment, etc) state for the
   current ML project
2. Create another Azure Blob Storage container for storing the state of CI/CD principals provisioned for the current
   ML project
3. Write credentials for accessing the container in (1) to a file
4. Create Databricks service principals configured for CI/CD, write their credentials to a file, and store their
   state in the Azure Blob Storage container created in (2).


Each `bootstrap.py` script will print out the path to a JSON file containing generated secret values
to store for CI/CD. **Note the paths of these secrets files for subsequent steps.** If either script
fails or the generated resources are misconfigured (e.g. you supplied invalid Git credentials for CI/CD
service principals when prompted), simply rerun and supply updated input values.

### Store generated secrets in CI/CD
Store each of the generated secrets in the output JSON files as
[GitHub Actions Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository),
where the JSON key
(e.g. `PROD_AZURE_SP_APPLICATION_ID`)
is the expected name of the secret in GitHub Actions and the JSON value
(without the surrounding `"` double-quotes) is the value of the secret. 

Note: The provided GitHub Actions workflows under `.github/workflows` assume that you will configure
[repo secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository),
but you can also use
[environment secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-environment)
to restrict access to production secrets. You can also modify the workflows to read secrets from another
secret provider.

### Add GitHub workflows to hosted Git repo
Create and push a PR branch adding the GitHub Actions workflows under `.github`:

```
git checkout -b add-cicd-workflows
git add .github
git commit -m "Add CI/CD workflows"
git push upstream add-cicd-workflows
```

Then, open and merge a pull request based on your PR branch to add
the CI/CD workflows to your hosted Git repo. Note that the CI/CD workflows will fail
until ML code is introduced to the repo in subsequent steps - you should
merge the pull request anyways.

After the pull request merges, pull the changes back into your local `main`
branch:

```
git checkout main
git pull upstream main
```

Finally, [create environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment)
in your repo named "staging" and "prod"

### Secret rotation
The generated CI/CD
Azure application client secrets have an expiry of [2 years](https://github.com/databricks/terraform-databricks-mlops-azure-project-with-sp-creation#outputs)
and will need to be rotated thereafter. To rotate CI/CD secrets after expiry, simply rerun `python .mlops-setup-scripts/cicd/bootstrap.py`
with updated inputs, after configuring auth as described in the prerequisites.

## Next steps
In this template, interactions with the staging and prod workspace are driven through CI/CD. After you've configured
CI/CD and ML resource state storage, you can productionize your ML project by testing and deploying ML code, deploying model training and
inference jobs, and more. See the [main project README](../README.md#productionizing-your-ml-project) for details.
