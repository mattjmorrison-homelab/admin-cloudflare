# Looked up by name, never hardcoded -- avoids a manual copy-paste of an
# ID that already exists in Cloudflare's own account.
data "cloudflare_zone" "morrisons_site" {
  filter = {
    name = local.zone_name
  }
}

# k8s-cloudflare's own bootstrap job (in-cluster) is what actually creates
# this tunnel if it doesn't exist yet -- this repo only ever reads it, to
# resolve the CNAME target every managed DNS record points at.
data "cloudflare_zero_trust_tunnel_cloudflareds" "homelab" {
  account_id = var.cf_account_id
  name       = local.tunnel_name
}

# Looks up the one pre-existing record (created by k8s-cloudflare's old
# bootstrap script, before this repo existed) so records.tf's import block
# can adopt it into this repo's state without Terraform trying to create a
# duplicate the Cloudflare API would reject.
data "cloudflare_dns_records" "argocd_existing" {
  zone_id = data.cloudflare_zone.morrisons_site.id
  type    = "CNAME"
  name = {
    exact = local.dns_records.argocd.hostname
  }
}
