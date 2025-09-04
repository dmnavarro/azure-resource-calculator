# Azure Region Resource Counter

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

- ✅ Count all resources in a subscription  
- ✅ Break down results by region  
- ✅ Filter by specific regions (e.g., `eastasia`, `southeastasia`)  
- ✅ Scan across **all subscriptions** in one go  
- ✅ Summarize totals per subscription and a **grand total**  
- ✅ Machine-readable JSON output option  

---

## 📦 Requirements

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- [jq](https://stedolan.github.io/jq/) (pre-installed in [Azure Cloud Shell](https://shell.azure.com/))

Login first if not already authenticated:

```bash
az login
