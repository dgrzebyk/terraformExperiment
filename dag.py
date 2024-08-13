from __future__ import print_function
from airflow.operators.dummy_operator import DummyOperator

from datetime import timedelta, datetime
import airflow
from airflow.contrib.operators.bigquery_operator import BigQueryOperator
from airflow.version import version as AIRFLOW_VERSION

### DATAFORM
from airflow.providers.google.cloud.operators.dataform import (
    DataformCancelWorkflowInvocationOperator,
    DataformCreateCompilationResultOperator,
    DataformCreateWorkflowInvocationOperator,
    DataformGetCompilationResultOperator,
    DataformGetWorkflowInvocationOperator,
)
from airflow.providers.google.cloud.sensors.dataform import DataformWorkflowInvocationStateSensor
from google.cloud.dataform_v1beta1 import WorkflowInvocation
from airflow import models
from airflow.models.baseoperator import chain

### TIMEZONE
import pendulum
from airflow.utils import timezone

sa_tz = pendulum.timezone('Africa/Johannesburg')

DAG_ID = 'cdc.dev-sap-central-data-lake.sap_hourly'
PROJECT_ID = 'dev-sap-central-data-lake'
REPOSITORY_ID = 'dev-sap-central-data-lake'
REGION = 'europe-west3'
WORKSPACE_ID = '02-DEV-DEPLOY-sap-central-data-lake'
GIT_COMMITISH = '02-DEV-DEPLOY-sap-central-data-lake'

default_dag_args = {
    'depends_on_past': False,
    'start_date': datetime(2024, 6, 11),
    'catchup': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=30),
    'schedule_interval': '@daily',
}

with airflow.DAG(DAG_ID,
                 default_args=default_dag_args,
                 catchup=False,
                 max_active_runs=1,
                 schedule_interval="@daily") as dag:
    compile_dataform = DataformCreateCompilationResultOperator(
        task_id='compile_dataform',
        project_id=PROJECT_ID,
        region=REGION,
        repository_id=REPOSITORY_ID,
        compilation_result={
            "git_commitish": GIT_COMMITISH,
            "code_compilation_config":
                {
                    "vars": {
                        "logsDatabase": "dev-sap-central-data-lake",
                        "finalDatabase": "dev-sap-central-data-lake",
                        "assetDatabase": "dev-sap-data-assets",
                    }
                }
        },
    )

    execute_dataform = DataformCreateWorkflowInvocationOperator(
        task_id='execute_dataform',
        project_id=PROJECT_ID,
        region=REGION,
        repository_id=REPOSITORY_ID,
        workflow_invocation={
            'compilation_result': "{{ task_instance.xcom_pull('compile_dataform')['name'] }}",
            'invocation_config': {"included_tags": ["sap hourly"]}
        },
    )

    stop_task = DummyOperator(task_id="stop")

    compile_dataform >> execute_dataform >> stop_task