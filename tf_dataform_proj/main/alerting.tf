/******************************************
	NOTIFICATION CHANNEL
 *****************************************/
resource "google_monitoring_notification_channel" "dataform_notification_channel" {
  display_name = "Dataform Notification Channel"
  type         = "email"

  labels = {
    email_address = "daniel.grzebyk@gmail.com"
  }
  force_delete = false
}

/******************************************
	ALERT POLICIES
 *****************************************/

resource "google_monitoring_alert_policy" "dataform_failure_alert_policy" {
  display_name = "Spreading ML Forecast Across PMs"
  combiner     = "OR"
  conditions {
    display_name = "pipeline failed condition"
    condition_matched_log {
        filter = "resource.type = \"dataform.googleapis.com/Repository\" AND severity = \"ERROR\" AND jsonPayload.terminalState=\"FAILED\" AND jsonPayload.workflowConfigId=\"add_dimensions\""
    }
  }

  notification_channels = ["${google_monitoring_notification_channel.dataform_notification_channel.id}"]

  documentation {
    content   = <<EOF
    # Dataform Pipeline Failed

    Log-based alert in project $${project} detected a failed Dataform workflow $${resource.labels.workflow_invocation_id}.

    To view the error logs in the Google Cloud console, go to
    https://console.cloud.google.com/bigquery/dataform/locations/europe-west3/repositories/add_dimensions/workflows/$${resource.labels.workflow_invocation_id}?project=$${project}

    For more questions, contact the Developer Support team.
    EOF
    mime_type = "text/markdown"
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
    auto_close = "1800s"
  }
}