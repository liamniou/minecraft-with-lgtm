output "minecraft_hostname" {
  description = "What to give your friends — type this in the Minecraft client"
  value       = "${var.subdomain}.${var.domain}"
}

output "minecraft_a_record" {
  description = "The A record that resolves to your home IP"
  value       = "${var.subdomain}.${var.domain} A ${var.server_ip}"
}

output "minecraft_srv_record" {
  description = "The SRV record (so clients don't have to type a port)"
  value       = "_minecraft._tcp.${var.subdomain}.${var.domain} SRV 0 5 ${var.minecraft_port} ${var.subdomain}.${var.domain}"
}
