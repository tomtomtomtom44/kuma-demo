#!/usr/bin/env python3
import argparse
import os
import sys
import yaml # Requires PyYAML: pip install pyyaml
import base64 # For encoding secret data


def parse_env_file(path: str) -> dict:
    """Parses a .env file into a dictionary."""
    env = {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                if v.startswith('"') and v.endswith('"'):
                    v = v[1:-1].replace('\\"', '"')
                elif v.startswith("'") and v.endswith("'"):
                    v = v[1:-1]
                env[k.strip()] = v
    except FileNotFoundError:
        print(f"Error: Input env file not found at {path}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error parsing env file {path}: {e}", file=sys.stderr)
        sys.exit(1)
    return env

def generate_namespace_yaml(k8s_namespace: str) -> dict:
    """Generates the Kubernetes Namespace YAML structure as a Python dictionary."""
    return {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "name": k8s_namespace
        }
    }

def generate_hcp_auth_secret_yaml(secret_name: str, k8s_namespace: str, client_id: str, client_secret: str) -> dict:
    """Generates the Kubernetes Secret YAML for HCP authentication."""
    # This function assumes client_id and client_secret are valid if called.
    # The main logic will handle whether to call it.
    return {
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {
            "name": secret_name,
            "namespace": k8s_namespace
        },
        "type": "Opaque",
        "data": {
            "clientID": base64.b64encode(client_id.encode('utf-8')).decode('utf-8'),
            "clientSecret": base64.b64encode(client_secret.encode('utf-8')).decode('utf-8')
        }
    }

def generate_hcp_sync_yaml(env_keys: list, hcp_app_name: str, hcp_secret_name: str, k8s_secret_name: str, k8s_namespace: str, sync_rule_name: str) -> dict:
    """Generates the HCPVaultSecretsApp YAML structure as a Python dictionary."""
    templates = {}
    line1 = f'{{{{- $jsonSecret := get .Secrets "{hcp_secret_name}" | fromJson -}}}}'

    for key in sorted(env_keys):
        line2 = f'{{{{- get $jsonSecret "{key}" -}}}}'
        template_text = f"{line1}\n{line2}"
        templates[key] = {"text": template_text}

    transformation_block = {
        "excludes": [
            ".*_dev$", 
            "^dev_.*", 
            ".*_raw.*", 
            ".*_prod$", 
            "^prod_.*"
        ],
        "templates": templates
    }

    yaml_structure = {
        "apiVersion": "secrets.hashicorp.com/v1beta1",
        "kind": "HCPVaultSecretsApp",
        "metadata": {
            "name": sync_rule_name,
            "namespace": k8s_namespace,
        },
        "spec": {
            "appName": hcp_app_name,
            "destination": {
                "name": k8s_secret_name,
                "create": True,
                "transformation": transformation_block
            },
            "refreshAfter": "1h"
        }
    }
    return yaml_structure

def main():
    parser = argparse.ArgumentParser(
        description="Generate Namespace, optionally HCP Auth Secret, and HCPVaultSecretsApp YAML."
    )
    parser.add_argument("--env-file", required=True, help="Path to the source .env file.")
    parser.add_argument("--hcp-secret-name", required=True, help="Name of the JSON secret in HCP Vault (e.g., dev_env).")
    parser.add_argument("--hcp-app", default="linguaplay", help="Name of the application in HCP Vault Secrets.")
    
    # Arguments for HCP Auth Secret (now optional)
    parser.add_argument("--hcp-auth-client-id", required=False, help="HCP Service Principal Client ID. Provide with client secret to create/update auth secret.")
    parser.add_argument("--hcp-auth-client-secret", required=False, help="HCP Service Principal Client Secret. Provide with client ID to create/update auth secret.")
    parser.add_argument("--hcp-auth-secret-name", default="vso-hcp-auth-secret", help="Name for the K8s secret holding HCP auth credentials.")

    parser.add_argument("--k8s-secret", default="linguaplay-secrets", help="Name of the K8s secret for app env vars.")
    parser.add_argument("--k8s-namespace", default="linguaplay", help="K8s namespace for all resources.")
    parser.add_argument("--sync-rule-name", default="linguaplay-sync-templated", help="Name for the HCPVaultSecretsApp CR.")
    parser.add_argument("--output", "-o", help="Optional: Path to write the output YAML file (default: stdout).")

    args = parser.parse_args()

    # Validate conditional requirement for HCP auth credentials
    generate_auth_secret = False
    if args.hcp_auth_client_id and args.hcp_auth_client_secret:
        generate_auth_secret = True
        print(f"HCP auth credentials provided. Will generate K8s secret '{args.hcp_auth_secret_name}'.", file=sys.stderr)
    elif args.hcp_auth_client_id or args.hcp_auth_client_secret:
        # Only one of the two was provided
        parser.error("Both --hcp-auth-client-id and --hcp-auth-client-secret must be provided together to create/update the HCP auth secret, or neither to skip.")
    else:
        print(f"HCP auth credentials not provided. Skipping generation of K8s secret '{args.hcp_auth_secret_name}'. Ensure it exists if VSO needs it.", file=sys.stderr)


    if not os.path.isfile(args.env_file):
        print(f"Error: Input env file not found at {args.env_file}", file=sys.stderr)
        sys.exit(1)

    env_data = parse_env_file(args.env_file)
    env_keys = list(env_data.keys())

    if not env_keys:
        print(f"Error: No keys found in {args.env_file}", file=sys.stderr)
        sys.exit(1)

    print(f"Generating YAML for Namespace '{args.k8s_namespace}' and HCPVaultSecretsApp '{args.sync_rule_name}'.", file=sys.stderr)

    all_yaml_outputs = []

    # 1. Generate Namespace YAML
    namespace_yaml_data = generate_namespace_yaml(args.k8s_namespace)
    all_yaml_outputs.append(yaml.dump(namespace_yaml_data, default_flow_style=False, sort_keys=False, indent=2))

    # 2. Conditionally Generate HCP Auth Secret YAML
    if generate_auth_secret:
        hcp_auth_secret_yaml_data = generate_hcp_auth_secret_yaml(
            args.hcp_auth_secret_name,
            args.k8s_namespace,
            args.hcp_auth_client_id,
            args.hcp_auth_client_secret
        )
        all_yaml_outputs.append(yaml.dump(hcp_auth_secret_yaml_data, default_flow_style=False, sort_keys=False, indent=2))
    
    # 3. Generate HCPVaultSecretsApp YAML
    hcp_sync_yaml_data = generate_hcp_sync_yaml(
        env_keys,
        args.hcp_app,
        args.hcp_secret_name,
        args.k8s_secret,
        args.k8s_namespace,
        args.sync_rule_name
    )
    all_yaml_outputs.append(yaml.dump(hcp_sync_yaml_data, default_flow_style=False, sort_keys=False, indent=2))

    # Combine YAML outputs
    combined_yaml_output = "---\n".join(all_yaml_outputs)


    if args.output:
        try:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(combined_yaml_output)
            print(f"Successfully wrote combined YAML to {args.output}", file=sys.stderr)
        except IOError as e:
            print(f"Error writing combined YAML to {args.output}: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(combined_yaml_output)

if __name__ == "__main__":
    main()