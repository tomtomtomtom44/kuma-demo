# Copilot Instructions for kuma-demo

## Project Overview
- This repository manages infrastructure for a Kuma service mesh demo, using Terraform, Helm, and Kubernetes manifests.
- Major components:
  - `terraform/`: Infrastructure as code for cloud and local environments, with modules for Grafana Cloud, Kuma, and Kubernetes clusters.
  - `helm/`: Helm charts for deploying Kuma, Grafana agents (monitoring, logging, tracing).
  - `scripts/`: Kubernetes SecretStore and ExternalSecret manifests for integrating with secret managers.

## Key Workflows
- **Terraform:**
  - Use `terraform/environments/dev/` for environment-specific configuration.
  - Modules are referenced from `terraform/modules/` (some as git submodules, e.g., `grafanacloud`).
  - To update a submodule, use `git submodule update --init --recursive` and commit the pointer change in the parent repo.
  - Environment variables for sensitive values (see module READMEs for `.envrc` examples).
- **Helm:**
  - Deploy Kuma: `helm install --namespace kuma-system -f values.yaml my-kuma-release .` (from `helm/kuma-standalone/dev`)
  - Deploy Grafana agents: Use the respective chart directories under `helm/` with `helm install` or `helm template`.
- **Kubernetes Secrets:**
  - Apply SecretStore and ExternalSecret manifests from `infisical-secrets/` to appropriate namespaces.

## Patterns & Conventions
- **Terraform modules** expect a `dashboards/` directory for JSON dashboards (see `grafanacloud` module README).
- **Submodules** are locked to specific commits for reproducibility. Always update the parent repo after changing submodule state.
- **Sensitive data** is managed via environment variables and not committed.
- **Dashboards** for Grafana are managed as JSON files and loaded via Terraform resources.

## Integration Points
- **Grafana Cloud:** Automated stack, service account, and token creation via Terraform.
- **Vault:** Access tokens can be registered in Vault (see module documentation).
- **Kubernetes:** Secrets and agents are deployed via manifests and Helm charts.

## Examples
- To update the Grafana Cloud submodule:
  ```sh
  cd terraform/modules/grafanacloud
  git checkout main
  git pull origin main
  cd ../../..
  git add terraform/modules/grafanacloud
  git commit -m "Update grafanacloud submodule"
  git push
  ```
- To apply secrets:
  ```sh
  kubectl apply -f scripts/secret-store-kuma.yaml
  kubectl apply -f scripts/external-secrets-kuma.yaml -n kuma-system
  ```

## References
- See `README.md` at the repo root and in modules for more details and environment setup.
- For submodule usage, see `.gitmodules` and module-specific `README.md` files.

---
If any conventions or workflows are unclear, please ask for clarification or check the relevant README files.
