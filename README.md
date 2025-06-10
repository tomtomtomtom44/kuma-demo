# infra for Kuma service mesh demo

# Synchronize HCP secrets with kubernetes cluster

first read secret from HCP into a local env file (exemple for grafana cloud secret loki dev)

go into scripts folder

Read secret into an env file (necessary to synchronize the JSON keys of the secret)

python read_write_hcp_secret.py read --secret-name grafana_cloud_loki_dev --env-file .env.grafana.loki.dev --client-id xxx
Enter HCP Client Secret: 
Requesting API token from HCP...
Successfully obtained API token.
Fetching composite secret 'grafana_cloud_loki_dev'...
Successfully fetched secret 'grafana_cloud_loki_dev'.
Successfully wrote 3 entries to .env.grafana.loki.dev

Synchronize generated env to a kubernetes secret

python generate_vso_sync_yaml.py \
    --env-file .env.grafana.loki.dev \
    --hcp-secret-name grafana_cloud_loki_dev \
    --hcp-app grafana \
    --k8s-namespace logging \
    --k8s-secret grafanaloki-secret \
    --hcp-auth-client-id xxx \
    --hcp-auth-client-secret xxx \
    --hcp-auth-secret-name "vso-demo-sp" \
    --sync-rule-name grafanaloki-sync-templated \
    | kubectl apply -f -
HCP auth credentials provided. Will generate K8s secret 'vso-demo-sp'.
Generating YAML for Namespace 'logging' and HCPVaultSecretsApp 'linguaplay-sync-templated'.
namespace/logging created
secret/vso-demo-sp created
hcpvaultsecretsapp.secrets.hashicorp.com/linguaplay-sync-templated created

grafana monitoring

python read_write_hcp_secret.py read --secret-name grafana_cloud_prometheus_dev --env-file .env.grafana.prometheus.dev --client-id xxx
Enter HCP Client Secret: 
Requesting API token from HCP...
Successfully obtained API token.
Fetching composite secret 'grafana_cloud_prometheus_dev'...
Successfully fetched secret 'grafana_cloud_prometheus_dev'.
Successfully wrote 2 entries to .env.grafana.prometheus.dev

python generate_vso_sync_yaml.py \
    --env-file .env.grafana.prometheus.dev \
    --hcp-secret-name grafana_cloud_prometheus_dev \
    --hcp-app grafana \
    --k8s-namespace monitoring \
    --k8s-secret grafanaprom-secret \
    --hcp-auth-client-id xxx \
    --hcp-auth-client-secret xxx \
    --hcp-auth-secret-name "vso-demo-sp" \
    --sync-rule-name grafanaprom-sync-templated \
    | kubectl apply -f -
HCP auth credentials provided. Will generate K8s secret 'vso-demo-sp'.
Generating YAML for Namespace 'monitoring' and HCPVaultSecretsApp 'grafanaprom-sync-templated'.
namespace/monitoring created
secret/vso-demo-sp created
hcpvaultsecretsapp.secrets.hashicorp.com/grafanaprom-sync-templated created

grafana tracing

python read_write_hcp_secret.py read --secret-name grafana_cloud_tempo_dev --env-file .env.grafana.tempo.dev --client-id xxx

python generate_vso_sync_yaml.py \
    --env-file .env.grafana.tempo.dev \
    --hcp-secret-name grafana_cloud_tempo_dev \
    --hcp-app grafana \
    --k8s-namespace tracing \
    --k8s-secret grafanatempo-secret \
    --hcp-auth-client-id xxx \
    --hcp-auth-client-secret xxx \
    --hcp-auth-secret-name "vso-demo-sp" \
    --sync-rule-name grafanatempo-sync-templated \
    | kubectl apply -f -

# Installing kuma mesh with helm

helm install --namespace kuma-system -f values.yaml my-kuma-release .

# Installing grafana loki agent with helm

helm install grafana-loki --namespace logging -f values.yaml .
NAME: grafana-loki
LAST DEPLOYED: Tue Jun  3 07:23:03 2025
NAMESPACE: logging
STATUS: deployed
REVISION: 1
TEST SUITE: None

# Installing grafana prometheus agent with helm

helm template grafana-monitoring --namespace monitoring -f values.yaml .