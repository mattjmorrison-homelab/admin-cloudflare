locals {
  # <tunnel-id>.cfargotunnel.com -- every managed hostname is a CNAME to
  # this same target, resolved by name lookup (data.tf), never hardcoded.
  tunnel_target = "${data.cloudflare_zero_trust_tunnel_cloudflareds.homelab.result[0].id}.cfargotunnel.com"
}

resource "cloudflare_dns_record" "records" {
  for_each = local.dns_records

  zone_id = data.cloudflare_zone.morrisons_site.id
  name    = each.value.hostname
  type    = "CNAME"
  content = local.tunnel_target
  ttl     = 1 # required for a proxied record -- Cloudflare treats this as "automatic"
  proxied = true
  comment = each.value.consumer
}

# Adopts the real argocd.morrisons.site record k8s-cloudflare's old
# bootstrap script created, before this repo existed -- without this,
# `apply` would try to create a second CNAME for the same hostname and the
# Cloudflare API would reject it as a duplicate. Declarative, reviewed in
# the normal plan/apply flow, same idea as the moved blocks used for
# admin-openbao's secret retirements.
import {
  to = cloudflare_dns_record.records["argocd"]
  id = "${data.cloudflare_zone.morrisons_site.id}/${data.cloudflare_dns_records.argocd_existing.result[0].id}"
}
