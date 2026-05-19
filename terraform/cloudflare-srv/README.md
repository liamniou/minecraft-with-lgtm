# cloudflare-srv — give your Minecraft server a real hostname

Two DNS records on a domain you own, so friends type `mc.tokyo3.eu` instead of
`84.55.x.y:25565`. About 40 lines of Terraform, free, no Cloudflare Tunnel
required (Tunnel's free tier is HTTP only — Minecraft's TCP protocol won't
flow through it).

## What this creates

| Record | Why |
|---|---|
| `mc.<domain>` — **A** → your public IPv4 | Resolves the hostname your friends type. `proxied = false` (orange-cloud breaks the Minecraft protocol). |
| `_minecraft._tcp.mc.<domain>` — **SRV** → `mc.<domain>:25565` | Lets the Java client omit the port. Connecting to `mc.<domain>` Just Works. |

## What this assumes

- You own a domain on Cloudflare (any plan, including free).
- Your router forwards external port 25565 → the Minecraft host's 25565.
- Your public IPv4 is stable enough that re-running `terraform apply`
  on rare changes is acceptable. (For ISPs that re-roll the IP daily,
  pair this with a ddns updater that writes back to the same record.)

## Setup

```sh
cd terraform/cloudflare-srv

cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars        # fill in token, zone_id, domain, server_ip

terraform init
terraform plan
terraform apply
```

Then test from any machine:

```sh
dig +short SRV _minecraft._tcp.mc.<your-domain>
dig +short A   mc.<your-domain>
```

In Minecraft → Multiplayer → Add Server → just type `mc.<your-domain>`.

## Getting the credentials

- **API token** — [Cloudflare dashboard → My Profile → API Tokens](https://dash.cloudflare.com/profile/api-tokens).
  Use the *Edit zone DNS* template, scope it to the one zone you're modifying.
  Avoid the legacy Global API Key.
- **Zone ID** — open your domain in the Cloudflare dashboard; it's in the
  *API* box on the right of the Overview page.

To keep the token out of files entirely:

```sh
export TF_VAR_cloudflare_api_token='cf-...'
terraform apply
```

## Honest caveats

- Your residential IP ends up in public DNS the moment you publish the A
  record. Anyone who knows your hostname can `dig` it and get your IP.
  That's true for *any* DNS-based exposure — including handing out the IP
  directly. If that's not acceptable, use a VPN-style overlay (Tailscale,
  Playit.gg) instead.
- Cloudflare's free *Tunnel* won't help here — the standard ingress is
  HTTP-only. Spectrum supports raw TCP but is a paid product.
- Changes propagate in ~5 minutes with the 300 s TTL. Lower it for
  testing, raise it for stability.
