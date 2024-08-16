# Link Dataform project with a GitHub repository
resource "google_dataform_repository" "repository" {
  provider = google-beta
  project  = var.project
  name     = "add_dimensions"
  region   = "europe-west3"
  service_account = "${google_service_account.dataform.email}"

  git_remote_settings {
      url = "https://github.com/dgrzebyk/dataform.git"
      default_branch = "main"
      authentication_token_secret_version = google_secret_manager_secret_version.secret_version.id
  }

  workspace_compilation_overrides {
    default_database = var.project
    schema_suffix = "_suffix"
    table_prefix = "prefix_"
  }
}

# Create a Dataform release configuration
resource "google_dataform_repository_release_config" "release_config" {
  provider = google-beta

  project    = google_dataform_repository.repository.project
  region     = google_dataform_repository.repository.region
  repository = google_dataform_repository.repository.name

  name          = "main"
  git_commitish = "main"

  code_compilation_config {
    default_database = var.project
    default_schema   = "allocation"
    default_location = local.region
    assertion_schema = "allocation_assertions"
    database_suffix  = ""
    schema_suffix    = ""
    table_prefix     = ""
    vars = {
      projectId = var.project
    }
  }
}

# Create a Dataform workflow configuration
resource "google_dataform_repository_workflow_config" "workflow" {
  provider = google-beta

  project        = google_dataform_repository.repository.project
  region         = google_dataform_repository.repository.region
  repository     = google_dataform_repository.repository.name
  name           = "add_dimensions"
  release_config = google_dataform_repository_release_config.release_config.id

  invocation_config {
    service_account = google_service_account.dataform.email
  }
}

# Create BigQuery tables to be populated by Dataform
resource "google_bigquery_dataset" "allocation" {
  dataset_id    = "allocation"
  location      = local.region
  project       = var.project
}

resource "google_bigquery_dataset" "allocation_assertions" {
  dataset_id    = "allocation_assertions"
  location      = local.region
  project       = var.project
}

resource "google_bigquery_table" "ratios_temp" {
  dataset_id = google_bigquery_dataset.allocation.dataset_id
  table_id   = "ratios_temp"
  deletion_protection = true
  schema = <<EOF
[
  {
    "name": "creation_fiscper",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "division",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "pm",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "finishing_group",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Horizon_1",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Horizon_2",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Horizon_3",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Horizon_4",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Horizon_5",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Horizon_6",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  }
]
EOF

}

resource "google_bigquery_table" "SNP_A005" {
  dataset_id = google_bigquery_dataset.allocation.dataset_id
  table_id   = "SNP_A005"
  deletion_protection = true
  schema = <<EOF
[
  {
    "name": "Production_week",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "DC",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "DC_Desc_",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "Finishing_group",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "PM",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "B_I__KG_",
    "type": "FLOAT64",
    "mode": "NULLABLE"
  },
  {
    "name": "Recalculated_S_OP_Plan__KG_",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Check",
    "type": "FLOAT64",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Allocation_Key",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "Allocation_Qty__KG_",
    "type": "INTEGER",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "creation_fiscper",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  },
  {
    "name": "file_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": ""
  }
]
EOF

}
