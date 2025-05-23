# infra for Kuma service mesh demo

# Synchronize HCP secrets with kubernetes cluster

kubectl create secret generic vso-demo-sp \
    --namespace kuma-system \
    --from-literal=clientID=xxx \
    --from-literal=clientSecret=xxx
secret/vso-demo-sp created

cf Issue #423 on the hashicorp/vault-secrets-operator

kubectl create namespace kuma-system
namespace/kuma-system created

python generate_vso_sync_yaml.py --env-file env.kuma.dev --hcp-secret-name kuma_tls_certificate_dev --k8s-secret kuma-tls-cert --k8s-namespace kuma-system --sync-rule-name kuma-sync-templated | kubectl apply -f -
Generating YAML for 3 keys found in env.kuma.dev (HCP Secret: kuma_tls_certificate_dev)...
hcpvaultsecretsapp.secrets.hashicorp.com/kuma-sync-templated created