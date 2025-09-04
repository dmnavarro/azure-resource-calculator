#!/usr/bin/env bash
set -euo pipefail

# azure_region_resource_counter.sh
# Count resources per region in Azure.
# Requires: Azure CLI (az) and jq (both available in Azure Cloud Shell).

# -----------------------------
# Usage / Help
# -----------------------------
usage() {
  cat <<'EOF'
Usage:
  azure-resource-calculator.sh [options]

Options:
  -s, --subscription  <SUB_ID_OR_NAME>   Subscription ID or name to scan.
  -r, --regions       <REG1,REG2,...>    Comma-separated Azure regions to include (e.g., "eastasia,southeastasia").
                                         If omitted, includes all regions.
  -a, --all-subscriptions                Scan all enabled subscriptions (overrides -s).
  -j, --json                              Output machine-readable JSON (in addition to human-readable text).
  -h, --help                              Show this help.

Examples:
  # Current/default subscription, all regions
  ./azure-resource-calculator.sh

  # Specific subscription (by ID or name), all regions
  ./azure-resource-calculator.sh -s 00000000-0000-0000-0000-000000000000

  # Specific subscription + only East/Southeast Asia
  ./azure-resource-calculator.sh -s "My Prod Sub" -r eastasia,southeastasia

  # All enabled subscriptions, all regions
  ./azure-resource-calculator.sh -a

Notes:
  • Resources with no location reported are bucketed as "global/none".
  • Requires 'az' login with sufficient permissions to list resources.
EOF
}

# -----------------------------
# Prereq checks
# -----------------------------
command -v az >/dev/null 2>&1 || { echo "ERROR: 'az' not found. Install Azure CLI."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: 'jq' not found. Please install jq."; exit 1; }

# Quick auth check (won't exit if not logged in, just tries to read account)
if ! az account show >/dev/null 2>&1; then
  echo "INFO: You appear to be logged out. Run: az login"
fi

# -----------------------------
# Parse args
# -----------------------------
SUB_INPUT=""
REGIONS_INPUT=""
ALL_SUBS=false
EMIT_JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--subscription)
      SUB_INPUT="${2:-}"; shift 2;;
    -r|--regions)
      REGIONS_INPUT="${2:-}"; shift 2;;
    -a|--all-subscriptions)
      ALL_SUBS=true; shift;;
    -j|--json)
      EMIT_JSON=true; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1"; usage; exit 1;;
  esac
done

# Turn "r1,r2,r3" into JSON array ["r1","r2","r3"]
REGIONS_JSON=""
if [[ -n "${REGIONS_INPUT}" ]]; then
  # normalize by trimming spaces and lowercasing
  IFS=',' read -r -a _arr <<<"${REGIONS_INPUT}"
  norm=()
  for r in "${_arr[@]}"; do
    rr="$(echo "$r" | tr '[:upper:]' '[:lower:]' | xargs)"
    [[ -n "$rr" ]] && norm+=("$rr")
  done
  if [[ ${#norm[@]} -gt 0 ]]; then
    REGIONS_JSON="$(printf '%s\n' "${norm[@]}" | jq -R . | jq -s .)"
  fi
fi

# -----------------------------
# Helpers
# -----------------------------

# Resolve a subscription input (ID or name) to a canonical ID and name.
resolve_subscription() {
  local sub_in="${1:-}"
  local sub_id sub_name
  sub_id="$(az account show --subscription "$sub_in" --query id -o tsv 2>/dev/null || true)"
  if [[ -z "$sub_id" ]]; then
    echo "ERROR: Unable to resolve subscription '$sub_in'." >&2
    return 1
  fi
  sub_name="$(az account show --subscription "$sub_in" --query name -o tsv)"
  echo "$sub_id|$sub_name"
}

# Return JSON array of resource locations in a subscription, optionally filtered to REGIONS_JSON.
# Also normalizes blank locations to "global/none" and lowercases regions.
region_counts_json() {
  local sub_id="$1"
  local regions_json="${2:-}"

  local res_json
  res_json="$(az resource list --subscription "$sub_id" -o json)"

  if [[ -n "$regions_json" ]]; then
    echo "$res_json" | jq --argjson regions "$regions_json" '
      map((.location // ""))                              # extract locations (may be "")
      | map( if .=="" then "global/none" else ascii_downcase end )
      | map(select($regions | index(.) != null))          # keep only requested regions
      | sort
      | group_by(.)
      | map({region: .[0], count: length})
    '
  else
    echo "$res_json" | jq '
      map((.location // ""))
      | map( if .=="" then "global/none" else ascii_downcase end )
      | sort
      | group_by(.)
      | map({region: .[0], count: length})
    '
  fi
}

# Print a human-readable table from the region-count JSON array.
print_region_table() {
  local json="$1"
  if [[ "$(echo "$json" | jq 'length')" -eq 0 ]]; then
    echo "  (no resources found for selected scope)"
    return
  fi

  # Sort by region name for deterministic output
  echo "$json" | jq -r '
    (["Region","Count"]),
    (.[] | [ .region, ( .count|tostring ) ]) 
    | @tsv
  ' | column -t -s $'\t' | sed '1s/.*/  &/' | sed '2s/.*/  &/'
}

# Sum counts from the region-count JSON array.
sum_counts() {
  local json="$1"
  echo "$json" | jq -r '(map(.count)|add) // 0'
}

# -----------------------------
# Build subscription list
# -----------------------------
declare -a SUBS_IDS
declare -a SUBS_NAMES

if "$ALL_SUBS"; then
  # All enabled subscriptions
  mapfile -t SUBS_IDS < <(az account list --query "[?state=='Enabled'].id" -o tsv)
  mapfile -t SUBS_NAMES < <(az account list --query "[?state=='Enabled'].name" -o tsv)
  if [[ ${#SUBS_IDS[@]} -eq 0 ]]; then
    echo "No enabled subscriptions found."
    exit 0
  fi
else
  if [[ -n "$SUB_INPUT" ]]; then
    resolved="$(resolve_subscription "$SUB_INPUT")" || exit 1
    SUBS_IDS+=( "$(echo "$resolved" | cut -d'|' -f1)" )
    SUBS_NAMES+=( "$(echo "$resolved" | cut -d'|' -f2)" )
  else
    # Default/current subscription
    cur_id="$(az account show --query id -o tsv)"
    cur_name="$(az account show --query name -o tsv)"
    if [[ -z "$cur_id" ]]; then
      echo "ERROR: Unable to determine current subscription. Use -s or run 'az account set'." >&2
      exit 1
    fi
    SUBS_IDS+=( "$cur_id" )
    SUBS_NAMES+=( "$cur_name" )
  fi
fi

# -----------------------------
# Main
# -----------------------------
GRAND_TOTAL=0
COMBINED_JSON='[]'

for i in "${!SUBS_IDS[@]}"; do
  SID="${SUBS_IDS[$i]}"
  SNAME="${SUBS_NAMES[$i]}"

  echo ""
  echo "=============================================="
  echo "Subscription: $SNAME ($SID)"
  echo "=============================================="

  RC_JSON="$(region_counts_json "$SID" "${REGIONS_JSON:-}")"
  TOTAL_FOR_SUB="$(sum_counts "$RC_JSON")"
  GRAND_TOTAL=$(( GRAND_TOTAL + TOTAL_FOR_SUB ))

  echo "Total resources: $TOTAL_FOR_SUB"
  echo "Region breakdown:"
  print_region_table "$RC_JSON"

  # Accumulate machine-readable output
  # shape: { subscriptionId, subscriptionName, total, regions: [{region,count}, ...] }
  SUB_JSON="$(jq -n \
    --arg sid "$SID" \
    --arg sname "$SNAME" \
    --argjson regions "$RC_JSON" \
    --argjson total "$TOTAL_FOR_SUB" \
    '{subscriptionId:$sid, subscriptionName:$sname, total:$total, regions:$regions}')"
  COMBINED_JSON="$(jq -n --argjson acc "$COMBINED_JSON" --argjson item "$SUB_JSON" '$acc + [$item]')"
done

if [[ ${#SUBS_IDS[@]} -gt 1 ]]; then
  echo ""
  echo "========== GRAND TOTAL across ${#SUBS_IDS[@]} subscriptions =========="
  echo "Grand total resources: $GRAND_TOTAL"
fi

if "$EMIT_JSON"; then
  echo ""
  echo "--- JSON OUTPUT ---"
  echo "$COMBINED_JSON" | jq '.'
fi