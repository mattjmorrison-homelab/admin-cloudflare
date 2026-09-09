# Not sensitive -- a tunnel ID grants no access on its own, same category
# as the zone/tunnel names in locals.tf. Useful for confirming the lookup
# resolved to the right tunnel without digging through provider internals.
output "tunnel_target" {
  value       = local.tunnel_target
  description = "The CNAME target every managed DNS record resolves to, resolved by tunnel name (homelab), not hardcoded."
}
