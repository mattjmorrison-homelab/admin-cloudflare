# GitHub's own published webhook-delivery source IP ranges
# (https://api.github.com/meta, the "hooks" field, checked 2026-09-10).
# GitHub does occasionally change these -- this is a static list, not
# auto-refreshed, so it needs a periodic manual re-check against that
# endpoint, same as any other externally-controlled allowlist.
locals {
  github_webhook_ip_ranges = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "143.55.64.0/20",
    "2a0a:a440::/29",
    "2606:50c0::/32",
  ]
}

# Defense-in-depth on top of ArgoCD's own webhook.github.secret HMAC
# signature check (real, populated, already verified independently of
# this rule) -- that check answers "is this payload really from GitHub";
# this answers "don't let non-GitHub traffic reach this path at all".
# Scoped narrowly to exactly the webhook path, not the whole hostname --
# everything else on argocd.morrisons.site is gated by Cloudflare Access
# instead (see access.tf).
resource "cloudflare_ruleset" "argocd_webhook_ip_allowlist" {
  zone_id     = data.cloudflare_zone.morrisons_site.id
  name        = "Restrict ArgoCD's GitHub webhook path to GitHub's published IPs"
  description = "Blocks any request to argocd.morrisons.site/api/webhook whose source IP isn't in GitHub's published webhook-delivery ranges."
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    {
      description = "Block non-GitHub traffic to the ArgoCD webhook path"
      expression  = "(http.host eq \"argocd.morrisons.site\" and http.request.uri.path eq \"/api/webhook\" and not ip.src in {${join(" ", local.github_webhook_ip_ranges)}})"
      action      = "block"
      enabled     = true
    }
  ]
}
