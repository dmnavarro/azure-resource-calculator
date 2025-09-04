# Azure Resource Counter

![Azure CLI](https://img.shields.io/badge/Azure%20CLI-%230078D4.svg?logo=microsoftazure&logoColor=white)
![jq](https://img.shields.io/badge/jq-JSON-blue)
![Shell](https://img.shields.io/badge/Shell-Bash-green)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A Bash script to **count Azure resources per region** in your subscription(s).

It supports:
- Scanning a **specific subscription**
- Scanning a **specific subscription and region(s)**
- Scanning **all enabled subscriptions across all regions**
- Generating both **human-readable tables** and optional **JSON output**

> Designed to run in **Azure Cloud Shell** (Bash), but works anywhere with `az` CLI and `jq` installed.

---

## ✨ Features

- Count all resources in a subscription  
- Break down results by region  
- Filter by specific regions (e.g., `eastasia`, `southeastasia`)  
- Scan across **all subscriptions** in one go  
- Summarize totals per subscription and a **grand total**  
- Machine-readable JSON output option  

---

## 📦 Requirements

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- [jq](https://stedolan.github.io/jq/) (pre-installed in [Azure Cloud Shell](https://shell.azure.com/))

Login first if not already authenticated:

```bash
az login
```

## 🚀 Usage:
```bash
  azure_region_resource_counter.sh [options]
```
### Options
| Flag | Description |
|------|-------------|
| `-s, --subscription <ID/NAME>` | Subscription ID or name to scan |
| `-r, --regions <REG1,REG2,...>` | Comma-separated list of regions (defaults to all) |
| `-a, --all-subscriptions` | Scan all enabled subscriptions (overrides `-s`) |
| `-j, --json` | Also output JSON results |
| `-h, --help` | Show help message |

### Examples:
  #### Current/default subscription, all regions
  ```bash
  ./azure_region_resource_counter.sh
  ```
  #### Specific subscription (by ID or name), all regions
  ```bash
  ./azure_region_resource_counter.sh -s 00000000-0000-0000-0000-000000000000
  ```
  #### Specific subscription + only East/Southeast Asia
  ```bash
  ./azure_region_resource_counter.sh -s 00000000-0000-0000-0000-000000000000 -r eastasia,southeastasia
  ```
  #### All enabled subscriptions, all regions
  ```bash
  ./azure_region_resource_counter.sh -a
  ```

#### Notes:
  • Resources with no location reported are bucketed as "global/none".
  • Requires 'az' login with sufficient permissions to list resources.

## 📊 Example Output

#### Human-readable table:

```bash
==============================================
Subscription: My Prod Sub (00000000-0000-0000-0000-000000000000)
==============================================
Total resources: 128
Region breakdown:
  Region         Count
  eastasia       45
  southeastasia  67
  global/none    16
```

#### JSON output (with -j):
```bash
[
  {
    "subscriptionId": "00000000-0000-0000-0000-000000000000",
    "subscriptionName": "My Prod Sub",
    "total": 128,
    "regions": [
      { "region": "eastasia", "count": 45 },
      { "region": "southeastasia", "count": 67 },
      { "region": "global/none", "count": 16 }
    ]
  }
]
```
## ⚠️ Notes

Resources with no explicit location are categorized as global/none.

Region names are normalized to lowercase for consistency.

Requires Reader (or higher) permissions on the subscription(s).

