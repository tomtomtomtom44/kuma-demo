#!/usr/bin/env python3
import requests, json, getpass, os, argparse, sys

# --- Configuration (Constants that don't change per environment) ---
HCP_ORG_ID               = "8c43a53b-ecb2-47b8-8218-6b6601517206"
HCP_PROJECT_ID           = "754a4ec1-aaaf-4d97-b904-5aaaa5502034"
HCP_APP_NAME             = "grafana" # Assuming app name is the same
HCP_API_BASE_URL         = "https://api.cloud.hashicorp.com"
HCP_AUTH_URL             = "https://auth.idp.hashicorp.com/oauth2/token"
HCP_SECRETS_API_VERSION  = "2023-11-28"
DEFAULT_ENV_FILE         = ".env.development" # Default might change based on env
# --- End Configuration ---

def get_hcp_api_token(client_id: str, client_secret: str) -> str:
    """Authenticates with HCP and returns an API access token."""
    # (No changes needed in this function)
    try:
        print("Requesting API token from HCP...")
        resp = requests.post(
            HCP_AUTH_URL,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={
                "client_id": client_id,
                "client_secret": client_secret,
                "grant_type": "client_credentials",
                "audience": "https://api.hashicorp.cloud",
            },
            timeout=10
        )
        resp.raise_for_status()
        print("Successfully obtained API token.")
        return resp.json().get("access_token")
    except requests.exceptions.RequestException as e:
        print(f"Error requesting API token: {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                print(f"Response body: {e.response.json()}")
            except json.JSONDecodeError:
                print(f"Response body: {e.response.text}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error decoding token response JSON: {e}")
        print(f"Response text: {resp.text}")
        return None

# Modified function to accept secret name
def fetch_composite_secret(api_token: str, secret_name: str) -> dict:
    """Fetches the composite JSON blob and returns it as a dict."""
    print(f"Fetching composite secret '{secret_name}'...")
    url = (
        f"{HCP_API_BASE_URL}/secrets/{HCP_SECRETS_API_VERSION}"
        f"/organizations/{HCP_ORG_ID}/projects/{HCP_PROJECT_ID}"
        f"/apps/{HCP_APP_NAME}/secrets/{secret_name}:open" # Use parameter
    )
    try:
        resp = requests.get(
            url,
            headers={"Authorization": f"Bearer {api_token}"},
            timeout=10
        )
        resp.raise_for_status()
        payload = resp.json()

        # Navigate into the 'secret' wrapper
        secret_obj = payload.get("secret")
        if not secret_obj or "static_version" not in secret_obj:
            # Check if the error is simply 'secret not found' which is common
            if payload.get("code") == 5: # Code 5 often means NotFound in gRPC/protobuf APIs
                 print(f"Error: Secret '{secret_name}' not found in HCP Vault.")
                 return None # Indicate not found vs other errors
            else:
                 print(f"Error: Unexpected payload structure when fetching '{secret_name}':")
                 print(json.dumps(payload, indent=2))
                 return None # Indicate other error

        json_str = secret_obj["static_version"].get("value", "{}")
        print(f"Successfully fetched secret '{secret_name}'.")
        return json.loads(json_str)
    except requests.exceptions.RequestException as e:
        print(f"Error fetching composite secret '{secret_name}': {e}")
        if hasattr(e, 'response') and e.response is not None:
             try:
                print(f"Response body: {e.response.json()}")
             except json.JSONDecodeError:
                print(f"Response body: {e.response.text}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error decoding secret response JSON: {e}")
        print(f"Response text: {resp.text}")
        return None

# Modified function to accept secret name
def write_composite_secret(api_token: str, secrets_dict: dict, secret_name: str) -> None:
    """Writes the dictionary as a JSON blob to the specified composite secret."""
    print(f"Writing composite secret '{secret_name}'...")
    url = (
        f"{HCP_API_BASE_URL}/secrets/{HCP_SECRETS_API_VERSION}"
        f"/organizations/{HCP_ORG_ID}/projects/{HCP_PROJECT_ID}"
        f"/apps/{HCP_APP_NAME}/secret/kv"
    )
    payload = {
        "name": secret_name, # Use parameter
        "value": json.dumps(secrets_dict, indent=2) # Add indent for readability in HCP UI
    }
    try:
        resp = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {api_token}",
                "Content-Type": "application/json"
            },
            json=payload,
            timeout=15
        )
        resp.raise_for_status()
        print(f"Successfully wrote secret '{secret_name}'.")
    except requests.exceptions.RequestException as e:
        print(f"Error writing composite secret '{secret_name}': {e}")
        if hasattr(e, 'response') and e.response is not None:
             try:
                print(f"Response body: {e.response.json()}")
             except json.JSONDecodeError:
                print(f"Response body: {e.response.text}")
        # Re-raise the exception after printing details
        raise e


def parse_env_file(path: str) -> dict:
    """Parses a .env file into a dictionary."""
    # (No changes needed in this function)
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
                env[k.strip()] = v # Store the key
    except FileNotFoundError:
        print(f"Error: Input env file not found at {path}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error parsing env file {path}: {e}", file=sys.stderr)
        sys.exit(1)
    return env

def write_env_file_from_dict(secrets: dict, path: str) -> None:
    """Writes a dictionary to a .env file."""
    # (No changes needed in this function)
    try:
        with open(path, "w", encoding="utf-8") as f:
            count = 0
            for k, v in secrets.items():
                # Basic quoting logic
                if isinstance(v, str) and any(c in v for c in ['\n','"',"'","=","#"," "]):
                     # More robust quoting: escape backslashes and double quotes, then wrap
                     escaped_v = v.replace('\\', '\\\\').replace('"', '\\"')
                     formatted_v = f'"{escaped_v}"'
                else:
                    formatted_v = str(v) # Ensure value is string

                f.write(f"{k}={formatted_v}\n")
                count += 1
        print(f"Successfully wrote {count} entries to {path}")
    except IOError as e:
        print(f"Error writing to {path}: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during file writing: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    p = argparse.ArgumentParser(
        description="Fetch or update a composite JSON secret in HCP Vault Secrets." # Updated description
    )
    p.add_argument("mode", choices=["read","write"], help="Mode: 'read' from HCP to local file, 'write' from local file to HCP.")
    # Add argument for the secret name
    p.add_argument(
        "--secret-name",
        required=True,
        help="Name of the composite secret in HCP Vault Secrets (e.g., dev_env, prod_env)."
    )
    p.add_argument(
        "--env-file",
        default=DEFAULT_ENV_FILE,
        help=f"Path to the local .env file (default: {DEFAULT_ENV_FILE})."
    )
    p.add_argument("--client-id", required=True, help="HCP Service Principal Client ID.")
    p.add_argument("--client-secret", help="HCP Service Principal Client Secret (will prompt if not provided).")
    args = p.parse_args()

    # Get secret securely if not provided
    client_secret = args.client_secret or getpass.getpass("Enter HCP Client Secret: ")
    if not client_secret:
         print("Error: Client Secret cannot be empty.", file=sys.stderr)
         sys.exit(1)

    # Get API Token
    token = get_hcp_api_token(args.client_id, client_secret)
    if not token:
        sys.exit(1) # Error message already printed by get_hcp_api_token

    # Execute chosen mode
    if args.mode == "read":
        data = fetch_composite_secret(token, args.secret_name)
        if data is not None: # Check if fetch was successful (None indicates error)
            write_env_file_from_dict(data, args.env_file)
        else:
            print(f"Exiting due to error fetching secret '{args.secret_name}'.", file=sys.stderr)
            sys.exit(1)
    elif args.mode == "write":
        if not os.path.isfile(args.env_file):
            print(f"Error: Input env file not found at {args.env_file}.", file=sys.stderr)
            sys.exit(1)
        try:
            env_data = parse_env_file(args.env_file)
            if not env_data:
                 print(f"Warning: No data parsed from {args.env_file}. Writing empty JSON object to HCP.", file=sys.stderr)
            write_composite_secret(token, env_data, args.secret_name)
        except Exception as e:
             print(f"Exiting due to error writing secret '{args.secret_name}': {e}", file=sys.stderr)
             sys.exit(1)

if __name__ == "__main__":
    main()