terraform {
  required_version = ">= 0.12"
  backend "gcs" { # Google Cloud Storage as backend store
    bucket  = "dataengineeringe2e" # GCS name
    prefix  = "tfstate/state.tfstate" # Folder within our GCS
  }
}
