terraform {
  required_version = ">= 1.11.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  # State lives in k8s-garage's tofu-state bucket, same pattern as every
  # other Terraform repo. Credentials come from AWS_ACCESS_KEY_ID/
  # AWS_SECRET_ACCESS_KEY env vars, not from this file.
  backend "s3" {
    bucket = "tofu-state"
    key    = "admin-cloudflare/terraform.tfstate"
    region = "garage"

    endpoints = {
      s3 = "http://garage.garage.svc.cluster.local:3900"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

# CLOUDFLARE_API_TOKEN comes from the environment (CI: fetched from OpenBao
# via actions-openbao; locally: your own token).
provider "cloudflare" {}
