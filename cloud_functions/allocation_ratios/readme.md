```
gcloud functions deploy allocation_ratios --gen2 --runtime=python311 --region=europe-west3 --source=. --entry-point=allocation_ratios --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" --trigger-event-filters="bucket=allocation_ratios" --memory=512MB 
```