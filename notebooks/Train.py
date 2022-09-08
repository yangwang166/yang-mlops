# Databricks notebook source
##################################################################################
# Model Training Notebook
##
# This notebook runs the MLflow Regression Pipeline to train and registers an MLflow model in the model registry.
#
# It's run as part of CI (to integration-test model training logic) and by an automated model training job
# defined under ``databricks-config``
#
# NOTE: In general, we recommend that you do not modify this notebook directly, and instead update data-loading
# and model training logic in Python modules under the `steps` directory.
# Modifying this notebook can break model training CI/CD.
#
# However, if you do need to make changes (e.g. to remove the use of MLflow Pipelines APIs),
# be sure to preserve the following interface expected by CI and the production model training job:
#
# Parameters:
#
# * env (optional): Name of the environment the notebook is run in (dev, staging, or prod). Defaults to "dev".
#                   You can add environment-specific logic to this notebook based on the value of this parameter,
#                   e.g. read training data from different tables or data sources across environments.
# * test_mode (optional): Whether the current notebook is running in "test" mode. Defaults to False. In the provided
#                         notebook, when test_mode is True, an extra "test" suffix is added to the names of
#                         MLflow experiments and registered models used for training. This separates the potentially
#                         many runs/models logged during integration tests from
#                         runs/models produced by staging/production model training jobs. You can use the value of this
#                         parameter to further customize the behavior of this notebook based on whether it's running as
#                         a test or for recurring model training in staging/production.
#
#
# Return values:
# * model_uri: The notebook must return the URI of the registered model as notebook output specified through
#              dbutils.notebook.exit() AND as a task value with key "model_uri" specified through
#              dbutils.jobs.taskValues(...), for use by downstream notebooks.
#
# For details on MLflow Pipelines and the individual split, transform, train etc steps below, including usage examples,
# see the Regression Pipeline overview documentation: https://mlflow.org/docs/latest/pipelines.html#regression-pipeline
# and Regression Pipeline API documentation: https://mlflow.org/docs/latest/python_api/mlflow.pipelines.html#module-mlflow.pipelines.regression.v1.pipeline
##################################################################################

# COMMAND ----------
# MAGIC %load_ext autoreload
# MAGIC %autoreload 2

# COMMAND ----------

# MAGIC %pip install -r ../requirements.txt

# COMMAND ----------

dbutils.widgets.dropdown("env", "dev", ["dev", "staging", "prod"], "Environment Name")
dbutils.widgets.dropdown("test_mode", "False", ["True", "False"], "Test Mode")

env = dbutils.widgets.get("env")
_test_mode = dbutils.widgets.get("test_mode")
test_mode = True if _test_mode.lower() == "true" else False
profile = f"databricks-test" if test_mode else f"databricks-{env}"

# COMMAND ----------

from mlflow.pipelines import Pipeline

p = Pipeline(profile=profile)

# COMMAND ----------

p.clean()

# COMMAND ----------

p.inspect()

# COMMAND ----------

p.run("ingest")

# COMMAND ----------

p.run("split")

# COMMAND ----------

p.run("transform")

# COMMAND ----------

p.run("train")

# COMMAND ----------

p.run("evaluate")

# COMMAND ----------

p.run("register")

# COMMAND ----------

p.inspect("train")

# COMMAND ----------

test_data = p.get_artifact("test_data")
test_data.describe()

# COMMAND ----------

model_version = p.get_artifact("registered_model_version")
model_uri = f"models:/{model_version.name}/{model_version.version}"
dbutils.jobs.taskValues.set("model_uri", model_uri)
dbutils.notebook.exit(model_uri)
