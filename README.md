# admin-cloudflare

Manages this homelab's Cloudflare zone and DNS records via Terraform,
using the official [`cloudflare/cloudflare`](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)
provider.

Before this repo existed, `k8s-cloudflare`'s own bootstrap script created
DNS records ad hoc via raw `curl` calls against Cloudflare's API --
idempotent (only ever created, never deleted or updated), but with no
declarative record of what should exist. That responsibility has moved
here entirely; `k8s-cloudflare`'s bootstrap script no longer touches DNS
records at all, only the tunnel itself.

## What this manages

- `data.tf` looks up the existing zone (`morrisons.site`) and Cloudflare
  Tunnel (`homelab`) by name -- both already created (the zone manually,
  the tunnel by `k8s-cloudflare`'s own bootstrap job) -- so nothing here
  needs a manually copy-pasted ID.
- `locals.dns_records` is the single source of truth for every public
  hostname the tunnel routes. Add an entry there and `records.tf`
  generates the `cloudflare_dns_record` resource -- nothing else needs
  editing to add a new hostname.
- Every managed record is a CNAME to the tunnel's `<id>.cfargotunnel.com`
  target, proxied through Cloudflare.

## Adopting a pre-existing record

`argocd.morrisons.site` already existed (created by the old bootstrap
script) before this repo's first apply. `records.tf`'s `import` block
adopts it into this repo's state declaratively -- looked up via
`data.cloudflare_dns_records.argocd_existing`, not a hardcoded record ID
-- so the first `tofu apply` here updates its tracking rather than trying
(and failing) to create a duplicate.

Adding a brand-new hostname later needs no such import -- only a
pre-existing record does, since only that state gap exists.

## Adding a new hostname

1. Add an entry to `locals.dns_records` in `locals.tf`.
2. Make sure `k8s-cloudflare`'s tunnel `ingress` config
   (`configmap-ingress.yaml`) routes that same hostname to something real
   in-cluster -- this repo only manages the public DNS side, not the
   tunnel's internal routing.

## Securing argocd.morrisons.site

`waf.tf` adds a Cloudflare WAF custom rule blocking any request to the
GitHub webhook path (`argocd.morrisons.site/api/webhook`) whose source
IP isn't in GitHub's own published webhook-delivery ranges
(`https://api.github.com/meta`'s `hooks` field). This is defense-in-depth
on top of ArgoCD's own `webhook.github.secret` HMAC signature check
(already real and active) -- the signature check answers "is this
payload really from GitHub", this rule answers "don't let non-GitHub
traffic reach the path at all". GitHub's ranges are a static, manually
checked list here, not auto-refreshed -- re-check periodically.

Everything else on that hostname (and any future protected hostname) is
gated by Cloudflare Access instead -- see the personal-access section
below.

## CI credentials

CI reads `cloudflare-api-token` and `cf-account-id` from OpenBao at
`kv/homelab/admin-cloudflare/*` -- this repo's own dedicated credential,
separate from `k8s-cloudflare`'s in-cluster `cloudflare-bootstrap` token.
Two different consumers must never share one credential, even when both
happen to authenticate against the same Cloudflare account -- that's the
sharing this homelab's secrets standard exists to prevent.

The token needs: `Zone:Read`, `DNS:Edit`, `Account:Cloudflare Tunnel:Read`
(read-only -- this repo only looks up the tunnel, never creates or edits
it), plus `Zone:WAF:Edit` (for `waf.tf` -- confirmed the correct
permission for the Rulesets engine `cloudflare_ruleset` uses; `Zone:
Firewall Services` is a different, older permission tied to the legacy
Firewall Rules API and isn't sufficient on its own) and
`Account:Access: Apps and Policies:Edit` (for the personal-access Access
Applications/Policies), all restricted to the `morrisons.site`
zone/account. Create/edit it in Cloudflare's dashboard and paste the
value into the scaffolded `kv/homelab/admin-cloudflare/cloudflare-api-token`
path, same as every other real credential in this homelab.
