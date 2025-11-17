# infra for Kuma service mesh demo

# Create infrastructure with terraform

This repo uses Terragrunt to generate and manage Terraform backends and inputs per-environment. Terragrunt is used to keep backend/workspace naming and common inputs DRY.

Quick steps (from repo root):

- Install dependencies (terragrunt and terraform).

- Pick an environment folder under `terraform/environments/` (for example `dev/grafanacloud` or `production/lke-k8s`).

- Prepare environment variables used by modules (see `terraform/environments/*/*/variables.tf` and module READMEs). Example (use a local `.envrc` or export directly):

```bash
export TF_VAR_grafana_auth="<GRAFANA_API_KEY>"
export TF_VAR_stack_name="<STACK_NAME>"
export TF_VAR_stack_slug="<STACK_SLUG>"
export TF_VAR_stack_region="eu"
export TF_VAR_environment="dev"
export TF_VAR_infisical_project_id="<INFISICAL_PROJECT_ID>"
export TF_VAR_infisical_client_id="<INFISICAL_CLIENT_ID>"
export TF_VAR_infisical_client_secret="<INFISICAL_CLIENT_SECRET>"
export VAULT_ADDR="<VAULT_ADDR>"
export VAULT_TOKEN="<VAULT_TOKEN>"
```

- Initialize and plan with Terragrunt (recommended so backend `backend.tf` is generated from `root.hcl`):

```bash
cd terraform/environments/<env>/<component>
terragrunt init      # generates backend.tf and initializes Terraform Cloud remote backend
terragrunt plan
```

- Apply (be careful with production):

```bash
terragrunt apply
```

Notes and details:

- The repository `terraform/environments/root.hcl` generates a `backend.tf` using `locals.common_vars.env` combined with the folder path to build a Terraform Cloud workspace name. Example generated backend for `dev/grafanacloud` becomes `dev-grafanacloud` and points to Terraform Cloud org `DTProd-org`.

- Each environment folder often contains a `terragrunt.hcl` that includes the repository `root.hcl` and a `main.tf` that instantiates the appropriate module under `terraform/modules/`.

- To run all child modules for an environment in sequence, you can use:

```bash
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

- If a module is a git submodule (see `terraform/modules/grafanacloud`), update and commit the submodule pointer in the parent repo after changing the submodule state:

```bash
git submodule update --init --recursive
cd terraform/modules/grafanacloud
# make changes, commit and push to that submodule remote's branch
git checkout main
git merge <your-commit-hash>
git push origin main
cd ../../..
git add terraform/modules/grafanacloud
git add .gitmodules
git commit -m "Update grafanacloud submodule"
git push
```

- Backend is Terraform Cloud remote (hostname `app.terraform.io`) as generated in `root.hcl`.

- See module `terraform/modules/grafanacloud/README.md` for module-specific env vars and dashboard layout.


# Configure K8S Infisical secrets stores and external secrets

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

## grafana tracing

create secret store in default namespace :

kubectl apply -f secret-store-tempo.yaml

create external secret in tracing namespace :

kubectl apply -f external-secrets-tempo.yaml -n tracing

# Install kuma mesh with helm

helm install --namespace kuma-system -f values.yaml my-kuma-release .

# Install grafana loki agent with helm

helm install grafana-loki --namespace logging -f values.yaml .
NAME: grafana-loki
LAST DEPLOYED: Tue Jun  3 07:23:03 2025
NAMESPACE: logging
STATUS: deployed
REVISION: 1
TEST SUITE: None

# Install grafana prometheus agent with helm

helm template grafana-monitoring --namespace monitoring -f values.yaml .

# Install grafana tempo agent with helm

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

# ArgoCD

Using this documentation : https://www.arthurkoziel.com/setting-up-argocd-with-helm/

helm repo add argo-cd https://argoproj.github.io/argo-helm
"argo-cd" has been added to your repositories

helm dep update argocd

 ~/VSCode-devops/kuma-demo/helm (main)
$ helm dep update argocd
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "hashicorp" chart repository
...Successfully got an update from the "external-secrets" chart repository
...Successfully got an update from the "argo-cd" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading argo-cd from repo https://argoproj.github.io/argo-helm
Deleting outdated charts

helm install argocd . -n argocd --create-namespace
NAME: argocd
LAST DEPLOYED: Mon Nov 17 08:09:03 2025
NAMESPACE: argocd
STATUS: deployed
REVISION: 1
TEST SUITE: None

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

kubectl port-forward svc/argocd-server -n argocd 8090:443
