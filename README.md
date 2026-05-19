# Self-hosted Minecraft + LGTM

A reference setup for a hobby-grade, production-shaped Minecraft server with the full Grafana **L**oki + **G**rafana + **T**empo-style + **M**etrics stack alongside it, plus a Discord ping when the server goes down.

Companion to the meetup talk **"Self-hosting with Minecraft: a hobby that saves you money (no)."** Slides in [slides/](slides/).

## What runs

| Service       | Port      | What it does                                                       |
|---------------|-----------|--------------------------------------------------------------------|
| `paper`       | 25565     | Minecraft (PaperMC, latest version). Auto-installs the Prometheus exporter plugin. |
| `paper`       | 9225      | Prometheus exporter (sladkoff plugin) — TPS, players, chunks, JVM. |
| `prometheus`  | 9090      | TSDB + rule evaluator. Receives metrics via `remote_write` from Alloy. No scrape configs. |
| `loki`        | 3100      | Log store.                                                         |
| `obs-alloy`   | 12345     | Grafana Alloy — **one agent for everything**: scrapes all metric targets → `remote_write` to Prometheus, tails `paper`'s `latest.log` → Loki. |
| `grafana`     | 3000      | Dashboards + Discord alerting. Provisioned datasources + dashboard.|
| `doco-cd`     | 9120      | [GitOps reconciler](https://github.com/kimdre/doco-cd) — polls this repo, reconciles compose stacks on change. |

## Quick start

```sh
# 1. One-time: copy the env template and put your Discord webhook in
cp .env.example .env
$EDITOR .env

# 2. Boot the stack stage by stage — the talk's "0 → production" path
docker compose -p self-hosted-minecraft -f compose.minecraft.yaml up -d   # Stage 0 — just Paper
docker compose -p self-hosted-minecraft -f compose.lgtm.yaml      up -d   # Stages 1-4 — LGTM + log shipper
docker compose                          -f compose.doco-cd.yaml   up -d   # Stage 5 — GitOps reconciler (separate project)

# 3. Watch Paper finish first boot (downloads world, plugins; ~2 minutes)
docker compose -p self-hosted-minecraft -f compose.minecraft.yaml logs -f paper
```

Open [http://localhost:3000](http://localhost:3000) — Grafana is anonymous-viewer-enabled, so the dashboard **Minecraft — eva01** is reachable without login. Admin is `admin / admin`.

Connect a Minecraft Java client to `localhost:25565`.

## Discord alert

Grafana provisions:

- a Discord **contact point** at [observability/grafana/provisioning/alerting/contact-points.yaml](observability/grafana/provisioning/alerting/contact-points.yaml) (reads `$DISCORD_WEBHOOK_URL` from the container env)
- a **notification policy** that routes every alert to that contact point
- one **alert rule** *Minecraft server is down* — fires after 1 minute of `up{job="minecraft"} == 0`

To test it: `docker compose stop paper` and wait ~90 seconds.

## Repo layout

```
.
├── compose.minecraft.yaml             Stage 0: just Paper (mirrors eva01 role)
├── compose.lgtm.yaml                  Stages 1-4: LGTM + log shipper (mirrors EVA-00 role)
├── compose.doco-cd.yaml               Stage 5: GitOps reconciler (separate compose project)
├── .doco-cd.yaml                      Doco-CD deployment manifest (read after `git pull`)
├── .env.example                       copy → .env, fill in Discord webhook + git token
├── minecraft/
│   ├── alloy.alloy                    log-shipper config (file → Loki)
│   └── data/                          generated on first boot (gitignored)
└── observability/
    ├── prometheus.yml                 scrape jobs
    ├── loki-config.yaml               single-binary Loki
    ├── alloy.alloy                    obs-side agent (mirrors prod)
    └── grafana/provisioning/
        ├── datasources/datasources.yaml
        ├── dashboards/dashboards.yaml
        ├── dashboards/minecraft.json
        └── alerting/{contact-points,policies,rules}.yaml
```

## Slides

The deck for the meetup talk lives in [slides/slides.md](slides/slides.md) and uses [Marp](https://marp.app/) (Markdown → PDF/PPTX). Strategic spine in [slides/NOTES.md](slides/NOTES.md).

## Caveats

- This is a **demo setup**. Don't expose port 25565 to the public internet without rate limiting / a firewall.
- Anonymous Grafana view is enabled so meetup attendees can see the dashboard without credentials. Disable `GF_AUTH_ANONYMOUS_ENABLED` in [compose.lgtm.yaml](compose.lgtm.yaml) for any real deployment.
- The Prometheus exporter plugin auto-downloads on first boot. If Spigot is unreachable, plugin install will fail silently and `:9225` will return nothing. Re-run `docker compose -p self-hosted-minecraft -f compose.minecraft.yaml up -d paper` once Spigot is reachable.
