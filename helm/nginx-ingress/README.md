# Nginx Ingress on LKE

This Helm chart captures the configuration observed on the `nginx-ingress`
release in namespace `default`:

- ingress-nginx chart `4.13.2` (controller `1.13.2`)
- one controller replica
- a `LoadBalancer` Service using `externalTrafficPolicy: Local`
- fixed HTTP/HTTPS NodePorts `31402` and `30574`
- PROXY protocol enabled in the controller and on the Linode NodeBalancer

The current cluster state had the PROXY protocol ConfigMap value and Linode
Service annotation in live resources, but neither was present in the release's
stored Helm values. This chart records both settings so a future Helm upgrade
re-applies them.

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

The command above changes the live release and may trigger a NodeBalancer
reconfiguration. Review the rendered output first. Kubernetes/Akamai assign the
Service IP, NodePorts, and health-check NodePort, so those values are not pinned
in this chart and may differ after recreation. The HTTP/HTTPS NodePorts are
pinned to their observed values; the health-check NodePort (`32614`) is assigned
by Kubernetes and may differ if the Service is recreated. Ensure the pinned
NodePorts are available before installing this chart in another cluster.

This reproduces the observed single-replica setup; it does not provide an
ingress pod on every worker node. With `externalTrafficPolicy: Local`, a worker
without a local controller pod can remain unhealthy in the NodeBalancer.