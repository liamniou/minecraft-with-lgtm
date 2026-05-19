# ============================================================================
# A record:  <subdomain>.<domain>  →  your public IP
# ============================================================================
# Must be DNS-only (proxied = false). Cloudflare's HTTP proxy doesn't carry
# raw Minecraft TCP, so orange-cloud here breaks the game protocol.

resource "cloudflare_record" "minecraft_a" {
  zone_id = var.zone_id
  name    = var.subdomain
  type    = "A"
  content = var.server_ip
  proxied = false
  ttl     = 300
  comment = "Minecraft server — points clients at the home router for port-forwarded 25565"
}

# ============================================================================
# SRV record:  lets clients type "mc.tokyo3.eu" without a port
# ============================================================================
# The Java Edition client looks up _minecraft._tcp.<host> on connect and
# follows the SRV target/port. So clients see a clean hostname; the actual
# IP+port live in DNS.

resource "cloudflare_record" "minecraft_srv" {
  zone_id = var.zone_id
  name    = "_minecraft._tcp.${var.subdomain}"
  type    = "SRV"
  ttl     = 300
  comment = "Minecraft SRV — lets clients omit the :25565 from the address"

  data {
    service  = "_minecraft"
    proto    = "_tcp"
    name     = var.subdomain
    priority = 0
    weight   = 5
    port     = var.minecraft_port
    target   = "${var.subdomain}.${var.domain}"
  }
}
