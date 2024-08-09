# terraformExperiment
This repository experiments with deploying GCP infrastructure using Terraform. The project contains:
Dataform pipeline containing a workflow and a release connected with a GitHub repository, BigQuery 
tables, a GCP secret containing a GitHub token, a dummy cloud function, and the necessary 
permissions. BigQuery tables don't have to be defined explicitly if Dataform service account obtains
permissions to create them.

## Folder structure
```
+-- function - contains dummy Cloud Function to be deployed
+-- tf_dataform_proj
|   +-- backend - determines where infrastructure state is stored. It is a nested terraform project 
|       that simply creates a Cloud Storage bucket. 
|   +-- environment - stores variables for development and production. Paths to these files must be 
|       provided when applying changes to Terraform infrastructure.
```

## Prerequisits
Terraform CLI installed on the local machine. In case you use multiple Terraform versions on one
machine please see ``tfenv`` tool [link](https://github.com/tfutils/tfenv). 

## What is Terraform?
Terraform is an Infrastructure as Code (IaC) tool that allows to create cloud resources 
programmatically instead of clicking through the user interface. This makes it easy to track, 
automate, and reproduce infrastructure. For more information please see [this link](https://developer.hashicorp.com/terraform/intro).

## Terraform States
Based on the code Terraform creates a local file containing the desired infrastructure and compares 
it with the state of the remote infrastructure. When prompted it removes or creates cloud resources
so the desired and the actual states are always the same. Backend is the place where the remote
state is stored. When using GCS backend, Terraform will lock your state for all operations that 
could write state. This prevents others from acquiring the lock and potentially corrupting your state.
Local state is created using ``terraform init``, it is well described by the [official documentation](https://developer.hashicorp.com/terraform/language/state):

>After you initialize, Terraform creates a .terraform/ directory locally. This directory 
contains the most recent backend configuration, including any authentication parameters you 
provided to the Terraform CLI. Do not check this directory into Git, as it may contain sensitive 
credentials for your remote backend.
> 
>The local backend configuration is different and entirely separate from the terraform.tfstate file 
that contains state data about your real-world infrastruture. Terraform stores the terraform.tfstate 
file in your remote backend.

## Security
Terraform state contains confidential information such as credentials which should never be revealed
in a text form. Therefore, they are defined in Terraform code and their values are assigned through
environment variables. If sensitive values are in your state, using a remote backend allows you to 
use Terraform without that state ever being persisted to disk.

You cannot declare TF variables as environment variables, you can only assign them.

After changing a backend's configuration, you must execute ``terraform init`` again to validate and 
configure the backend before you can perform any plans, applies, or state operations.

## Deploying infrastructure in a new GCP project
To recreate infrastructure from this repository in a new GCP project you need to:
1. create a GCS bucket that will store remote Terraform state. You can do it either manually, or by 
running ``terraform init`` from the `backend` directory. 
2. provide a GitHub token as an environment variable by running `set TF_VAR_github_token=YOUR_GITHUB_TOKEN` 
on Windows or`export TF_VAR_github_token=YOUR_github_token` on Linux/MacOS. 
3. initialize the Terraform project containing the infrastructure definitions by running 
`terraform init` from the `tf_dataform_proj` directory. 
4. create the defined infrastructure by running ``terraform apply -var-file=environment\dev.tfvars`` 
from the `tf_dataform_proj` directory.

## Clean up
To destroy the infrastructure run `terraform destroy -var-file=environment\dev.tfvars` from
the `tf_dataform_proj` directory. BigQuery tables have `force_delete=True` which ensures they 
cannot be accidentally deleted by running `terraform destroy`. Similar is the case for the Dataform
repository which cannot be removed because it contains nested resources (workflow and a release).
These resources can be only destroyed manually by running 
``dataform destroy -target=YOUR_RESOURCE_NAME --var-file=environment/dev.tfvars``. In case resources
were defined using `for each` parameter their names must contain quotation marks ("") preceded by
a backslash. For example, to destroy `allocation` BigQuery table you must run 
``terraform destroy -target=google_bigquery_dataset.bigquery_datasets[\"allocation\"] --var-file=environment/dev.tfvars``. 
Resources unaffected by ``terraform destroy`` can be also removed manually in GCP UI.

## Contributions
This document contains direct quotes from Terraform documentation. It was written by Daniel Grzebyk. 
