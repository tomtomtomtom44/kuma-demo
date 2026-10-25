# Cloudflare Tunnel connector

This chart deploys two `cloudflared` connectors using the token synchronized by
the `cloudflared` ExternalSecret in the `cloudflare` namespace. Required pod
anti-affinity places the two connectors on distinct nodes. The rollout replaces
one connector at a time without creating a temporary third pod. The chart
creates no Service or public listener; connectors establish outbound
connections to Cloudflare.

Both pods require two eligible nodes. If only one is available, one connector
will remain Pending by design rather than colocating both replicas.

Apply the ExternalSecret first and wait until it is ready:

```sh
kubectl apply -f infisical-secrets/external-secrets-cloudflare.yaml
kubectl get externalsecret cloudflared -n cloudflare
```

Install or upgrade the connector from the repository root:

```sh
helm upgrade --install cloudflared ./helm/cloudflared \
  --namespace cloudflare --create-namespace
```

The tunnel's public hostnames and origin services are configured separately in
the Cloudflare dashboard for this remotely managed tunnel. Set each origin to
the appropriate application `ClusterIP` Service, for example
`http://<service>.<namespace>.svc.cluster.local:<port>`.

Do not route this tunnel directly to the current ingress-nginx Service without
changing its protocol configuration: ingress-nginx currently expects PROXY
protocol, while `cloudflared` sends ordinary HTTP to an HTTP origin. Routing to
the application Service directly avoids that protocol mismatch. Cloudflare
Access or WAF rules are configured in Cloudflare, not in this chart.

Check connector readiness and logs after deployment:

```sh
kubectl rollout status deployment/cloudflared -n cloudflare
kubectl get pods -n cloudflare -o wide
kubectl logs deployment/cloudflared -n cloudflare
```