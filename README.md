# infra for Kuma service mesh demo

# Synchronize HCP secrets with kubernetes cluster

## kuma tls cert

create secret store in default namespace :

kubectl apply -f secret-store-kuma.yaml

create external secret in kuma-system namespace :

kubectl apply -f external-secrets-kuma.yaml -n kuma-system

## grafana monitoring

create secret store in default namespace :

kubectl apply -f secret-store-prometheus.yaml

create external secret in monitoring namespace :

kubectl apply -f external-secrets-prometheus.yaml -n monitoring

## grafana logging

create secret store in default namespace :

kubectl apply -f secret-store-loki.yaml

create external secret in logging namespace :

kubectl apply -f external-secrets-loki.yaml -n logging

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

# Installing grafana tempo agent with helm

helm template grafana-tracing --namespace tracing -f values.yaml .
helm install grafana-tracing --namespace tracing -f values.yaml .

# Managing git submodule

The error:

```
fatal: Unable to find refs/remotes/origin/HEAD revision in submodule path 'terraform/modules/grafanacloud'
```

means that the submodule repository does not have a default branch (like `main` or `master`) set as `origin/HEAD`, or your local submodule clone is missing remote refs.

**How to fix:**

1. **Go into the submodule directory:**
   ```
   cd terraform/modules/grafanacloud
   ```

2. **Fetch all branches and tags:**
   ```
   git fetch origin
   ```

3. **Check available branches:**
   ```
   git branch -r
   ```

4. **Set the default branch if needed (replace `main` with the actual branch name):**
   ```
   git remote set-head origin main
   ```

5. **Checkout the desired commit or branch:**
   ```
   git checkout 018c1c32063a11e3582b538109451c063a57fdc1
   ```

6. **Go back to your main repo:**
   ```
   cd ../../..
   ```

7. **Update the submodule reference if needed:**
   ```
   git add terraform/modules/grafanacloud
   git commit -m "Fix submodule to correct commit"
   ```

If you still have issues, make sure the submodule repo URL in .gitmodules is correct and accessible. If the submodule repo is private, ensure you have access.

ok it seems ok now but the current submodule repo seems to be in detached mode and not on the last version of remote main, i don't understand why :
thoma@PC-Thomas MINGW64 ~/VSCode-devops/kuma-demo/terraform/modules/grafanacloud ((018c1c3...))
$ git status
HEAD detached at 018c1c3
nothing to commit, working tree clean

This is expected behavior for Git submodules.  
When you update a submodule, Git checks out the specific commit referenced by the parent repository—not necessarily the tip of the remote branch (like `main`). That’s why you see:

```
HEAD detached at 018c1c3
```

**Why?**  
- Submodules are meant to be locked to a specific commit for reproducibility.
- Even if the remote `main` branch has newer commits, your submodule will stay at the commit referenced in the parent repo until you explicitly update it.

**If you want the submodule to track the latest `main` branch:**

1. In the submodule directory:
   ```
   git checkout main
   git pull origin main
   ```
2. Go back to your main repo and update the submodule reference:
   ```
   cd ../../..
   git add terraform/modules/grafanacloud
   git commit -m "Update grafanacloud submodule to latest main"
   ```

**Summary:**  
Detached HEAD is normal for submodules. To use the latest code, you must manually update the submodule and commit the new reference in the parent repo.