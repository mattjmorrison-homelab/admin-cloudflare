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

## CI credentials

CI reads `cloudflare-api-token` and `cf-account-id` from OpenBao at
`kv/homelab/k8s-cloudflare/*` -- the same two real values
`k8s-cloudflare`'s own in-cluster `cloudflare-bootstrap` role already
reads. No new secret was scaffolded for this repo; `admin-openbao`'s
`admin-cloudflare` role is a second, narrower grant over those same two
existing keys, read-only.
