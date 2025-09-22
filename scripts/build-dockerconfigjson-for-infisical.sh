#!/usr/bin/env bash
# Build dockerconfigjson for GHCR and optionally prepare it for Infisical.
# Safe-by-default: the script writes a local file and prints the exact Infisical CLI command
# you can run manually or from CI to push the value.

set -euo pipefail

usage(){
  cat <<EOF
Usage: $0 --username <gh-user> --pat <gh-pat> --out <out-file> --project-id <infisical-project-id> --env <infisical-env> --path <infisical-path>

This script creates a kubernetes dockerconfigjson blob for ghcr.io and writes it to --out (or stdout if --out -).
It then prints the Infisical CLI command you can run to push that value into Infisical.

Options:
  --username        GitHub username (or org) for GHCR
  --pat             GitHub PAT with write:packages and read:packages
  --out             Output file path (use - for stdout). Default: ./dockerconfigjson.encoded
  --project-id      Infisical project id (used to print the CLI command)
  --env             Infisical environment name (e.g., dev)
  --path            Infisical secret path to store the dockerconfigjson (e.g. //linguaplay/ghcr)

Example:
  $0 --username tomtomtomtom44 --pat \
    --out ./dockerconfigjson.encoded \
    --project-id "789034fb-ac50-..." --env dev --path "//linguaplay/ghcr"

EOF
}

# Defaults
OUT_FILE="./dockerconfigjson.encoded"
INFISICAL_PROJECT_ID=""
INFISICAL_ENV="dev"
INFISICAL_PATH=""
GH_USER=""
GH_PAT=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --username) GH_USER="$2"; shift 2;;
    --pat) GH_PAT="$2"; shift 2;;
    --out) OUT_FILE="$2"; shift 2;;
    --project-id) INFISICAL_PROJECT_ID="$2"; shift 2;;
    --env) INFISICAL_ENV="$2"; shift 2;;
    --path) INFISICAL_PATH="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

if [[ -z "$GH_USER" || -z "$GH_PAT" ]]; then
  echo "Error: --username and --pat are required"
  usage
  exit 2
fi

# Build dockerconfigjson
AUTH_B64=$(printf "%s:%s" "$GH_USER" "$GH_PAT" | base64 -w 0 || true)
DOCKERCONFIGJSON=$(jq -n --arg auth "$AUTH_B64" '{"auths": {"ghcr.io": {"auth": $auth}}}')

# Kubernetes expects the .dockerconfigjson field base64 encoded inside the secret data.
# We will base64 the raw JSON for convenience for uploading to secret backends that expect the full value.
DOCKERCONFIGJSON_B64=$(printf '%s' "$DOCKERCONFIGJSON" | base64 -w 0 || true)

if [[ "$OUT_FILE" = "-" ]]; then
  echo "$DOCKERCONFIGJSON_B64"
else
  echo "$DOCKERCONFIGJSON_B64" > "$OUT_FILE"
  echo "Wrote base64-encoded dockerconfigjson to: $OUT_FILE"
fi

# Print recommended Infisical CLI command (non-destructive; does not execute)
if [[ -n "$INFISICAL_PROJECT_ID" && -n "$INFISICAL_PATH" ]]; then
  cat <<EOF

To push this value to Infisical using the Infisical CLI (if you have it installed), run the following command.
(Replace placeholders with your values if needed.)

# Example (writes the secret key 'dockerconfigjson' under the provided path):
# NOTE: adapt the 'infisical' CLI args to match your CLI version if necessary.

infisical secrets set \
  --env="$INFISICAL_ENV" \
  --projectId="$INFISICAL_PROJECT_ID" \
  --path="$INFISICAL_PATH" \
  "dockerconfigjson"="$(cat "$OUT_FILE")"

If you prefer to update via the Infisical web UI, open the project and add the key 'dockerconfigjson' under the path '$INFISICAL_PATH' and paste the following base64 value as the value:

$(if [[ "$OUT_FILE" != "-" ]]; then cat "$OUT_FILE"; else echo "(base64 value was printed to stdout)"; fi)

After updating Infisical, ExternalSecrets in your cluster will pick up the change based on its refreshInterval.
Remember to rotate the GH PAT in GitHub and then re-run this script to update Infisical.
EOF
else
  echo
  echo "Infisical project id or path not provided; the script only wrote the encoded dockerconfigjson to $OUT_FILE"
  echo "You can upload that value to Infisical using your preferred method (CLI or UI)."
fi

exit 0
