# Nginx Ingress on LKE

This Helm chart configures the `nginx-ingress` release in namespace `default`
as an internal controller; public application traffic is routed by Cloudflare
Tunnel directly to the application Services:

- ingress-nginx chart `4.13.2` (controller `1.13.2`)
- two controller replicas, required to schedule on distinct nodes
- rollout replaces one controller at a time to avoid requiring a third pod's CPU
- a `ClusterIP` Service with no public NodeBalancer or NodePorts
- PROXY protocol disabled because in-cluster clients use ordinary HTTP/HTTPS

The previous Service used a Linode NodeBalancer and PROXY protocol. Upgrading
with these values changes it to `ClusterIP`; Kubernetes/LKE should then remove
the NodeBalancer associated with that Service. The Cloudflare Tunnel routes
must already point directly to the application Services before this change.

## Render and deploy

From this directory, fetch the pinned dependency and inspect the rendered
resources:

```sh
helm dependency update
helm template nginx-ingress . --namespace default
```

To deploy or upgrade the release:

```sh
helm upgrade --install nginx-ingress . --namespace default --create-namespace
```

The command above changes the live release and is expected to remove its public
NodeBalancer. Review the rendered output and confirm Cloudflare Tunnel is
serving all required hostnames before deploying it.

Two replicas with required pod anti-affinity are configured for the current
two-worker cluster. If only one eligible worker is available, the second
replica remains Pending until another eligible node is available.

The existing `letsencrypt-http` ClusterIssuer still uses HTTP-01 through the
`nginx` IngressClass. Keep the controller and its Ingress resources until
certificate renewal has been migrated to another solver, such as DNS-01, or
until you have otherwise verified that HTTP-01 is no longer needed.