# Cloudflare DDNS

A simple bash script that automatically updates a Cloudflare DNS A record when your external IP changes.

## What It Does

1. Fetches your Zone ID from Cloudflare using the zone name
2. Retrieves the current DNS A record for your domain
3. Gets your external IP address from ifconfig.me
4. Compares the external IP with the current DNS record
5. Updates the DNS record if the IPs differ
6. Repeats every 5 minutes (configurable)

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `API_TOKEN` | Cloudflare API Token with DNS edit permissions | Yes |
| `ZONE_NAME` | Your Cloudflare zone name (e.g., example.com) | Yes |
| `RECORD_NAME` | The DNS record to update (e.g., home.example.com) | Yes |
| `SLEEP_INTERVAL` | Seconds between checks (default: 300) | No |

## Docker

```bash
docker run -d \
  -e API_TOKEN=your_token \
  -e ZONE_NAME=example.com \
  -e RECORD_NAME=home.example.com \
  ghcr.io/yourusername/cloudflare-ddns:latest
```

## Docker Compose

```yaml
services:
  cloudflare-ddns:
    image: ghcr.io/yourusername/cloudflare-ddns:latest
    environment:
      - API_TOKEN=your_token
      - ZONE_NAME=example.com
      - RECORD_NAME=home.example.com
      - SLEEP_INTERVAL=300
    restart: unless-stopped
```

## GitHub Container Registry

The image is automatically built and pushed to GHCR on every push to main:
```
ghcr.io/yourusername/cloudflare-ddns:latest
```
