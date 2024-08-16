import os
import functions_framework
import pandas as pd

from cloudevents.http import CloudEvent
from google.cloud import bigquery, storage


@functions_framework.cloud_event
def allocation_ratios(cloud_event: CloudEvent):
    data = cloud_event.data
    for env_var in ['GOOGLE_CLOUD_PROJECT_ID', 'BQ_DATASET', 'BQ_TABLE']:
        if not os.environ.get(env_var):
            raise ValueError(f"{env_var} environment variable not set")

    project_id = os.environ.get('GOOGLE_CLOUD_PROJECT_ID')
    dataset_id = os.environ.get('BQ_DATASET')
    table_id = os.environ.get('BQ_TABLE')

    # Variables required for logging
    event_id = cloud_event["id"]
    event_type = cloud_event["type"]
    metageneration = data["metageneration"]
    timeCreated = data["timeCreated"]
    updated = data["updated"]

    # Variables required for the function
    bucket_name = data['bucket']
    file_name = data['name']

    client = storage.Client(project_id)
    bucket = client.get_bucket(bucket_name)
    bucket.blob(file_name).download_to_filename(file_name)

    df = pd.read_excel(file_name, usecols="A:J")
    df['creation_fiscper'] = df['creation_fiscper'].ffill().astype(str)
    df['creation_fiscper'] = df['creation_fiscper'].astype(str).str.replace('.0', '')
    for n in range(1, 7):
        df['Horizon_{}'.format(n)] = df['Horizon_{}'.format(n)].astype(float)

    schema = [
        bigquery.SchemaField('creation_fiscper', 'STRING'),
        bigquery.SchemaField('division', 'STRING'),
        bigquery.SchemaField('pm', 'STRING'),
        bigquery.SchemaField('finishing_group', 'STRING'),
        bigquery.SchemaField('Horizon_1', 'FLOAT64'),
        bigquery.SchemaField('Horizon_2', 'FLOAT64'),
        bigquery.SchemaField('Horizon_3', 'FLOAT64'),
        bigquery.SchemaField('Horizon_4', 'FLOAT64'),
        bigquery.SchemaField('Horizon_5', 'FLOAT64'),
        bigquery.SchemaField('Horizon_6', 'FLOAT64')
    ]

    bq_destination = f'{project_id}.{dataset_id}.{table_id}'

    # Preventing duplicates
    query = f"""
        DELETE
        FROM `{bq_destination}`
        WHERE creation_fiscper = '{df['creation_fiscper'].iloc[0]}'
    """
    bq_client = bigquery.Client(project_id)
    bq_client.query(query).result()

    print("Uploading data to BigQuery...")
    job_config = bigquery.LoadJobConfig(schema=schema)
    job_config.write_disposition = bigquery.WriteDisposition.WRITE_APPEND
    job = bq_client.load_table_from_dataframe(df, bq_destination, job_config=job_config)
    job.result()
    print(f'{file_name} successfully uploaded to BigQuery.')

    return event_id, event_type, bucket_name, file_name, metageneration, timeCreated, updated
