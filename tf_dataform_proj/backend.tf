
/******************************************
	Remote backend configuration
 *****************************************/

# setup of the backend gcs bucket that will keep the remote state

terraform {
  backend "gcs" {
    bucket = "${var.project}_tf_state"
    prefix = ""
  }
}
