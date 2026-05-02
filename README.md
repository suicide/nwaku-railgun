# nwaku-railgun

Standalone Helm chart for deploying `nwaku` with configurable persistence, secret management, private or public network exposure, and websocket ingress.

## Chart Location

The chart lives at `charts/nwaku-railgun`.

Example values files live under `charts/nwaku-railgun/examples`.

## Design Notes

- Helm-native naming and namespaces are used by default.
- The chart is provider-agnostic for ingress TLS.
- TLS is configured using standard Kubernetes ingress fields.
- Provider-specific behavior such as `cert-manager` or Traefik is configured through ingress annotations.
- Public address advertisement is explicit. The chart does not infer public multiaddrs from ingress settings.

## Install

```bash
helm upgrade --install nwaku ./charts/nwaku-railgun \
  --namespace waku \
  --create-namespace \
  -f values.yaml
```

The chart fails fast unless you configure one secret strategy:

- `secrets.existingSecret=<name>`
- `secrets.create=true`

## Minimum Working Install

Use an existing secret for a private in-cluster Railgun node:

```yaml
secrets:
  existingSecret: nwaku-secrets
```

Or create the secret in-chart:

```yaml
secrets:
  create: true
  data:
    nodekey: "your-node-key"
```

## Core Configuration

### Secrets

Use an existing secret:

```yaml
secrets:
  create: false
  existingSecret: nwaku-secrets
```

Create the secret from chart values:

```yaml
secrets:
  create: true
  data:
    nodekey: "your-node-key"
```

When `config.rlnRelay.enabled=true`, the secret must also include:

- `rlnRelayCredPassword`
- `keystore`

### Persistence

Create a PVC:

```yaml
persistence:
  enabled: true
  size: 10Gi
```

Use an existing PVC:

```yaml
persistence:
  enabled: true
  existingClaim: nwaku-data
```

Disable persistence for ephemeral storage:

```yaml
persistence:
  enabled: false
```

## Examples

### Private In-Cluster Node

This is the default exposure model. The node stays private, can still connect out to external peers, and uses the Railgun peer defaults.

```yaml
secrets:
  existingSecret: nwaku-secrets
```

### Public Node

Public p2p exposure is opt-in. Enable the p2p service and, if needed, websocket ingress separately.

```yaml
secrets:
  existingSecret: nwaku-secrets

service:
  p2p:
    enabled: true
    type: NodePort
```

For a publicly reachable node, service exposure and public address advertisement are separate concerns. Enabling `service.p2p` exposes ports, but it does not automatically publish usable external multiaddrs. Configure `config.network.advertise.enabled=true` and set explicit `config.network.advertise.extMultiaddrs` when you want peers to discover the node via your public address.

Example:

```yaml
service:
  p2p:
    enabled: true
    type: NodePort

config:
  network:
    advertise:
      enabled: true
      extMultiaddrOnly: true
      extMultiaddrs:
        - "/dns4/waku.example.com/tcp/30000/p2p/16Uiu2..."
        - "/dns4/waku.example.com/tcp/443/wss/p2p/16Uiu2..."
```

### Public Websocket Ingress With cert-manager

```yaml
secrets:
  existingSecret: nwaku-secrets

service:
  p2p:
    enabled: true
    type: NodePort
  websocket:
    enabled: true

ingress:
  websocket:
    enabled: true
    className: nginx
    host: waku.example.com
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      enabled: true
      secretName: waku-websocket-tls
```

### Public Websocket Ingress With Traefik

```yaml
secrets:
  existingSecret: nwaku-secrets

service:
  p2p:
    enabled: true
    type: NodePort
  websocket:
    enabled: true

ingress:
  websocket:
    enabled: true
    className: traefik
    host: waku.example.com
    annotations:
      traefik.ingress.kubernetes.io/router.entrypoints: websecure
      traefik.ingress.kubernetes.io/router.tls: "true"
      traefik.ingress.kubernetes.io/router.tls.certresolver: le-http
    tls:
      enabled: true
      secretName: waku-websocket-tls
```

### Existing TLS Secret Without Provider-Specific Automation

```yaml
secrets:
  existingSecret: nwaku-secrets

service:
  websocket:
    enabled: true

ingress:
  websocket:
    enabled: true
    host: waku.example.com
    tls:
      enabled: true
      secretName: waku-websocket-tls
```

## Exposure Model

- `service.rpc` is intended to stay internal by default.
- `service.p2p` controls public or private libp2p/discv5 exposure.
- `service.websocket` exposes the websocket backend service.
- `ingress.websocket` adds external websocket routing and optional TLS termination.

Default private exposure uses:

- `service.p2p.enabled=false`
- `service.websocket.enabled=false`
- `ingress.websocket.enabled=false`

Public exposure uses:

- `service.p2p.type=NodePort`
- `service.p2p.enabled=true`

## Additional Peers

The default peer list is Railgun-specific. You can also append peers from an independently hosted fleet:

```yaml
config:
  network:
    additionalStaticNodes:
      - "/dns4/waku1.privatepaymaster.com/tcp/30000/p2p/16Uiu2HAkypTi3rsec2pkht6vUGTQHr2fkMjsACwM5hpEqEnrcyvE"
      - "/dns4/waku2.privatepaymaster.com/tcp/30000/p2p/16Uiu2HAmSbCr93dtYB3hAckmXKd3B5Qo7S9YoSri3exjLhGYBWfd"
```

## Development

Lint the chart:

```bash
helm lint ./charts/nwaku-railgun
```

Render the chart:

```bash
helm template nwaku ./charts/nwaku-railgun
```
