# Azure Resource Calculator

This script helps you **inventory all Azure resources** across subscriptions and regions, providing both a summary in the terminal and a structured JSON output file.  

It’s useful for:
- Auditing and compliance checks  
- Cloud resource visibility across subscriptions  
- Feeding resource counts into dashboards or reports  

---

## 🚀 Features
- **Cross-Subscription Coverage** — Works across all subscriptions available to your account  
- **Region Awareness** — Breaks down resources by Azure region  
- **JSON Output** — Saves results in a machine-friendly format for dashboards or automation  
- **Error Handling** — Clear messages if dependencies or permissions are missing  

---

## 📋 Prerequisites
Before using the script, ensure you have:
- **Azure CLI** installed → [Install Guide](https://learn.microsoft.com/cli/azure/install-azure-cli)  
- **jq** installed → [Install Guide](https://stedolan.github.io/jq/download/)  
- Logged in with Azure CLI:  
  ```bash
  az login
