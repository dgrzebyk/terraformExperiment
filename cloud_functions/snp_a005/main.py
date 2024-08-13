# Date:   July 3rd, 2024
# Author: Daniel Grzebyk

import os
import functions_framework
import pandas as pd

from cloudevents.http import CloudEvent
from google.cloud import bigquery
from datetime import date


def get_fiscper(date):
    """This function gets fiscal period matching the given date."""
    bq_client = bigquery.Client("sales-forecasting-378609")
    query = f"""
        SELECT CAST(fiscper AS STRING) AS fiscper
        FROM `sales-forecasting-378609.raw.fiscalCalendar`
        WHERE '{date}' BETWEEN start_fiscperDate AND end_fiscperDate
    """
    fiscper = bq_client.query(query).to_dataframe().iloc[0, 0]
    return fiscper


def get_schema():
    schema = [
        bigquery.SchemaField("Production_week", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("DC", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("DC_Desc_", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("Finishing_group", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("PM", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("B_I__KG_", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("Recalculated_S_OP_Plan__KG_", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("Check", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("Allocation_Key", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("Allocation_Qty__KG_", "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("creation_fiscper", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("file_name", "STRING", mode="NULLABLE")
    ]
    return schema


def change_dtypes(df):
    # Define the column type changes
    dtype_changes = {
        'Production_week': str,
        'DC': str,
        'DC_Desc_': str,
        'Finishing_group': str,
        'PM': str,
        'B_I__KG_': float,
        'Recalculated_S_OP_Plan__KG_': float,
        'Check': float,
        'Allocation_Key': str,
        'Allocation_Qty__KG_': int,
        'creation_fiscper': str,
        'file_name': str
    }

    # Apply the changes using astype
    df = df.astype(dtype_changes)
    return df


@functions_framework.cloud_event
def save_snp_a005_to_bq(cloud_event: CloudEvent):
    data = cloud_event.data
    project_id = "sales-forecasting-378609"

    # Variables required for logging
    event_id = cloud_event["id"]
    event_type = cloud_event["type"]
    metageneration = data["metageneration"]
    timeCreated = data["timeCreated"]
    updated = data["updated"]

    # Variables required for the function
    bucket_name = cloud_event.data['bucket']
    file_path = cloud_event.data['name']
    file_name = file_path.split('/')[-1]
    print(f"Processing file {file_path}")

    gs_filepath = f'gs://{bucket_name}/' + file_path
    bq_client = bigquery.Client(project_id)

    if '.xlsx' in file_path:
        # Loading the data from a SNP_A005 report (.xlsx)
        df = pd.read_excel(gs_filepath, sheet_name="SNP_A005", engine='openpyxl', skiprows=49)

        # Get current fiscal period
        dt = str(date.today())
        creation_fiscper = get_fiscper(dt)
        df['creation_fiscper'] = creation_fiscper

        df['file_name'] = file_name
        df.rename(columns={"Production week": "Production_week", "DC Desc.": "DC_Desc_",
                           "Finishing group": "Finishing_group", "B&I (KG)": "B_I__KG_",
                           "Recalculated S&OP Plan (KG)": "Recalculated_S_OP_Plan__KG_",
                           "Allocation Key": "Allocation_Key",
                           "Allocation Qty (KG)": "Allocation_Qty__KG_"}, inplace=True)

        # Uploading the data
        schema = get_schema()
        df = change_dtypes(df)
        table_id = f'{project_id}.allocation.SNP_A005'

        # Preventing duplicates (creation_fiscper could be replaced with file name)
        query = f"""
            DELETE
            FROM {table_id}
            WHERE creation_fiscper = '{creation_fiscper}'
        """
        bq_client.query(query).result()

        print("Uploading data to BigQuery...")
        job_config = bigquery.LoadJobConfig(schema=schema)
        job_config.write_disposition = bigquery.WriteDisposition.WRITE_APPEND
        job = bq_client.load_table_from_dataframe(df, table_id, job_config=job_config)
        job.result()
        print("File loaded successfully!")
    else:
        print("File format not supported!")

    return event_id, event_type, bucket_name, file_name, metageneration, timeCreated, updated
