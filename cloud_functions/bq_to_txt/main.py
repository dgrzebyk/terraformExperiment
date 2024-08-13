# Date:   July 8th, 2024
# Author: Daniel Grzebyk

import functions_framework

from datetime import date
from google.cloud import bigquery, storage


@functions_framework.http
def bq_to_txt(request):

    request_json = request.get_json(silent=True)
    request_args = request.args

    if request_json and 'project_id' in request_json:
        project_id = request_json['project_id']
    elif request_args and 'project_id' in request_args:
        project_id = request_args['project_id']
    else:
        return 'Project ID not provided', 400

    # Assuming dataset_id and destination_bucket are also passed in the same way
    dataset_id = 'allocation'
    destination_bucket = 'allocation_txt'

    bq_client = bigquery.Client(project_id)
    gcs_client = storage.Client(project_id)

    for table_id in ['GR_upload', 'PSP_upload']:
        gr_query = f"""
            SELECT *
            FROM `{project_id}.{dataset_id}.{table_id}`
        """
        df = bq_client.query(gr_query).to_dataframe()

        # Saving .txt file in the format required by SAP
        current_dt = str(date.today())
        destination_file_name = table_id + f'_{current_dt}' + '.txt'
        # Fails to save if the file already exists
        df.to_csv(destination_file_name, header=0, index=None, sep='\t', mode='x')

        # Upload the .txt file to Cloud Storage
        bucket = gcs_client.bucket(destination_bucket)
        blob = bucket.blob(destination_file_name)

        blob.upload_from_filename(destination_file_name)

    return 'Function executed successfully', 200
