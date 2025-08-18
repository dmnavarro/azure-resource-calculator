#!/bin/bash
# =============================================================================
# Azure Resource Calculator
# =============================================================================
# Description:
# This script calculates the total number of Azure resources across
# all subscriptions and regions available to your account, and saves
# the results to a JSON file.
#
# Prerequisites:
# 1. Azure CLI installed (`az --version`)
# 2. jq installed (`jq --version`)
# 3. Logged in with `az login` (interactive or service principal)
#
# Required Permissions:
# - Microsoft.Resources/subscriptions/list
# - Microsoft.Resources/subscriptions/resources/read
#
# Usage:
# ./azure-resource-calculator.sh
#
# Output:
# - Displays resource count per subscription and region
# - Shows overall total resource count
# - Saves results to `azure-calculation-results.json`:
#     [
#       {
#         "subscription_id": "<GUID>",
#         "region": "<region-name>",
#         "count": <number>
#       },
#       ...
#     ]
# =============================================================================

set -e

function handle_error() {
  echo "Error: $1"
  exit 1
}

# Prerequisite checks
command -v az >/dev/null 2>&1 || handle_error "Azure CLI (az) is not installed"
command -v jq >/dev/null 2>&1 || handle_error "jq is not installed"

echo "Fetching Azure subscriptions..."
subs_output=$(az account list --query '[].id' -o tsv) || handle_error "Failed to get subscriptions"
if [ -z "$subs_output" ]; then
  handle_error "No subscriptions found or not authenticated"
fi

echo "Counting resources per subscription and region..."
all_results=()
overall_total=0

for sub in $subs_output; do
  echo "-------------------------------------------------------"
  echo "Switching to subscription: $sub"
  az account set --subscription "$sub" || handle_error "Cannot set subscription $sub"

  # Retrieve all regions (locations) for current subscription
  regions=$(az account list-locations --query '[].name' -o tsv) || handle_error "Failed to list locations"

  for region in $regions; do
    echo -n "Processing $sub in region $region... "

    count=$(az resource list --location "$region" --query 'length(@)' -o tsv 2>/dev/null) || count=0

    echo "$count resources"

    all_results+=("{\"subscription_id\":\"$sub\",\"region\":\"$region\",\"count\":$count}")
    overall_total=$((overall_total + count))
  done
done

echo "-------------------------------------------------------"
echo "Total Azure resources across all subscriptions and regions: $overall_total"

# Save results to JSON file
echo "Saving results to azure-calculation-results.json..."
printf "[\n%s\n]\n" "$(printf "%s,\n" "${all_results[@]}" | sed '$ s/,$//')" > azure-calculation-results.json

echo "Done."
