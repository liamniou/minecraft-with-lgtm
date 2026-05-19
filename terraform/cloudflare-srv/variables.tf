# ============================================================================
# Cloudflare authentication
# ============================================================================
# The API token needs Zone:DNS:Edit on the zone you point `zone_id` at.
# Create one at: https://dash.cloudflare.com/profile/api-tokens

variable "cloudflare_api_token" {
  description = "Cloudflare API token (Zone:DNS:Edit on the target zone)"
  type        = string
  sensitive   = true
}

# ============================================================================
# DNS target
# ============================================================================

variable "zone_id" {
  description = "Cloudflare Zone ID for your domain (find it in the dashboard sidebar)"
  type        = string
}

variable "domain" {
  description = "Apex domain you own (e.g. tokyo3.eu)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for the Minecraft server (e.g. 'mc' → mc.tokyo3.eu)"
  type        = string
  default     = "mc"
}

# ============================================================================
# Server reachability
# ============================================================================

variable "server_ip" {
  description = "Public IPv4 of your home (the one your router forwards 25565 from). Must be a routable address — see README for the dynamic-IP note."
  type        = string
}

variable "minecraft_port" {
  description = "Port your router forwards to the Minecraft container"
  type        = number
  default     = 25565
}
