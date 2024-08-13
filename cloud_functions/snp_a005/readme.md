```
gcloud functions deploy save_snp_a005_to_bq --gen2 --runtime=python311 --region=europe-west3 --source=. --entry-point=save_snp_a005_to_bq --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" --trigger-event-filters="bucket=snp_a005" --memory=512MB 
```