resource "databricks_mlflow_model" "registered_model" {
  name = "${local.env_prefix}yang-mlops-project-model"
  depends_on = [
    databricks_job.batch_inference_job,
    databricks_job.model_training_job
  ]
  description = <<EOF
MLflow registered model for the "yang-mlops-project" ML Project. See the corresponding [Git repo](${var.git_repo_url}) for details on the project.

Links:
* [Git Repo](${var.git_repo_url}): contains ML code for the current project.
* [Recurring model training job](https://adb-1005182519515014.14.azuredatabricks.net#job/${databricks_job.model_training_job.id}): trains fresh model versions using the latest ML code.
* [Model deployment pipeline](${var.git_repo_url}/actions/workflows/deploy-model-${local.env}.yml): deploys model versions produced by the training job.
* [Recurring batch inference job](https://adb-1005182519515014.14.azuredatabricks.net#job/${databricks_job.batch_inference_job.id}): applies the latest ${local.env} model version for batch inference.
EOF
}
