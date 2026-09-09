# The one zone/tunnel this homelab uses. Not sensitive -- names, same
# category as a namespace or repo name -- so they live here in plain
# committed config rather than OpenBao.
locals {
  zone_name   = "morrisons.site"
  tunnel_name = "homelab"

  # Every public hostname the Cloudflare tunnel actually routes today.
  # One cloudflare_dns_record per entry (see records.tf), all pointing at
  # the same tunnel target. `consumer` is documentation only (which
  # in-cluster service this hostname reaches) -- matches admin-discord's
  # webhooks map convention.
  dns_records = {
    argocd = {
      hostname = "argocd.morrisons.site"
      consumer = "k8s-cloudflare's tunnel ingress -> argocd-server.argocd.svc.cluster.local"
    }
  }
}
