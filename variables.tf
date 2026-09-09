# Cloudflare account ID -- fetched from OpenBao in CI
# (kv/homelab/k8s-cloudflare/cf-account-id), the same real value
# k8s-cloudflare's own bootstrap job uses. Not sensitive in the "grants
# access" sense (it's an identifier, not a credential), but kept as a
# variable rather than hardcoded since it's fetched fresh in CI same as
# the API token, not committed to this repo.
variable "cf_account_id" {
  type        = string
  sensitive   = true
  description = "Cloudflare account ID that owns the zone and tunnel this repo manages."
}
