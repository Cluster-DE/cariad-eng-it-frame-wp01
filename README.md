
# Multi-Region File Share Solution

## Overview

This project automates infrastructure deployment using Terraform and sets up virtual machines (VMs) with a PowerShell-based bootstrapping process. This process mounts an Azure file share onto VMs, ensuring secure cross-region connectivity using Azure Private Link. Resources span two regions: Europe (EU) and the United States (US), and all VMs are equipped with essential software dependencies (e.g., .NET SDK).

## Requirements

- **Terraform**
- **Azure CLI**
- **PowerShell**

## Solution Architecture

![](./architecture.drawio.png)

## Infrastructure as Code (IaC)

We leverage **Terraform** to automate and modularize the deployment of resources, adhering to best practices for security and maintainability.

**Terraform Structure and Naming Conventions:**

Resources follow a standardized naming pattern based on the environment and region:
- **EU Resources:** \${var.environment}\${var.project_short_name}\${var.location_short_eu}
- **US Resources:** \${var.environment}\${var.project_short_name}\${var.location_short_us}

### Key Variables:
- `var.environment`: Specifies the environment (e.g., dev, prod).
- `var.project_short_name`: Abbreviated project identifier.
- `var.location_short_eu`: Short code for the EU region.
- `var.location_short_us`: Short code for the US region.

### Modular Design

We employ a modular approach for maintainability, where each module includes:
1. **inputs.tf**: Defines the required inputs for the module.
2. **main.tf**: Contains the resource definitions.
3. **outputs.tf**: Provides the outputs needed by other modules.

**Directory Structure:**
```
- main.tf
- terraform.tfvars (local development file, ignored in version control)
- modules/
  - module_1/
  - module_2/
  - module_x/
    - inputs.tf
    - main.tf
    - outputs.tf
```

## Resource Overview

### Virtual Machines
- **OS**: Windows 11
- **Replicability**: VM scaling as needed. Terraform can setup x VMs by just creating a new module call.
- **Scripts & Dependencies**: VMs use extensions to automate the mounting of the Azure file share and manage software dependencies. Accessible via RDP.

### Storage Account
- Standard storage account with an Azure file share.
- Secured using a private link.
- Option: [Azure File Sync](https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-planning). It's a new service from Microsoft, primarily meant for hybrid cloud architecture. It optimizes file sharing & adds features like syncing existing Windows Server fileshares to a cloud-native fileshare, giving you the freedom to use other Cloud services like private endpoints on top.
We decided this to not be included in the PoC scope, but this can be a valid consideration.

### Key Vault
- Stores secrets and sensitive information for the project.

### Virtual Networks (VNets)
- Two VNets, one per region (EU and US).
- VNets are peered, with security managed at the VNet level using Network Security Groups (NSGs).

## PowerShell VM Bootstrapping

### Script Functions

Two scripts are involved:
1. **Service Creation Script**: Executed through Terraform, this script initializes the VM to set up the environment, including autostart for further scripts.
2. **Bootstrapping Script**: Uploaded via CustomScriptExtension and executed on startup, this script installs .NET SDK, configures the environment, and mounts the file share.

### Logging
- Both scripts log activities under `C:\CustomScriptLogs` for detailed process tracking and debugging.

## Networking Design

### VNet Peering

The solution creates two VNets (EU and US), peered to facilitate secure, internal communication across regions:
- **VNet A (EU)**: Hosts the primary storage account with the Azure file share.
- **VNet B (US)**: Contains VMs that access the file share through private endpoints.

### Private Link for Secure Access

Private Link secures access to the storage account, ensuring the file share is only reachable through the internal network:
- **Private Endpoints**: Enable VMs in VNet B to securely access the file share in VNet A.

### DNS Configuration

For Private Link to function properly, DNS must be configured to resolve private endpoints:
- **Private DNS Zone**: Ensures that both VNets can resolve the storage account's private domain.

### File Share Connectivity

The bootstrapping script configures VMs in VNet B to mount the file share securely using Private Link, ensuring that credentials persist across reboots.

## Common Issues & Resolutions

### VM and Script Issues
- **Credential Setting Failure**: Review the file share log if credential management fails.
- **File Share Mounting Failure**: Ensure that Private Link and DNS settings are correct.
- **.NET SDK Installation Issues**: Check the bootstrapping log for download or installation errors.
- **CustomScriptExtension Challenges**: Some tasks (e.g., `cmdkey` credential management) fail when executed under the CustomScriptExtension context but work under direct execution. Consider using Windows services for more reliable script execution.
- **Provisioning Failures**: When CustomScriptExtensions fail initially, Terraform can lose track of their state. Manual intervention may be required.
- **Windows File Share Bug**: Occasionally, programmatically created file shares show as "disconnected," but remain functional. This is a known issue requiring further investigation.
- **Environment variables Bug**: When setting environment variables with cmdlets like setx or SetEnvironmentVariable, the variable isn't set. We got it to work only by using direct registry entries. 
### Terraform & Azure Limitations
- **Storage Account Tier Restrictions**: Private Link cannot be used with premium storage accounts (SSDs), limiting performance choices.
- **Cross-Region ServiceConnections**: These are restricted to the same region, making cross-region deployments challenging when using ServiceConnections.
- **Storage account without public access disables GitHub Agents & local development**: When disabling public access, the azure resource manager behind terraform cannot access resources like blobs & fileshares. This issue can be solved by creating or connecting a ci/cd agent with our vnet. For local development we have the same case - we would need to use a VPN to allow that. 
Alteratively, we can also allow the current ip address of the agent or the developer before deployment. 

## Ansible playbook configuration

The limited time available did not allow for the development, testing, and fine-tuning of Ansible configurations. Instead, we opted for Terraform, which allowed us to quickly provision and configure the required infrastructure in a more time-efficient manner, leveraging its declarative approach and our team's familiarity with the tool. This ensured that we met the deadline while maintaining the desired configuration outcomes.

## Performance measurement report

The project under `src/Benchmark` is designed to evaluate the performance of the Azure File Share by benchmarking file upload and download operations. The benchmarking is implemented using a .NET-based tool in conjunction with the BenchmarkDotNet library, providing detailed insights into the performance characteristics under different conditions.

### Benchmarking approach

The tool measures the performance of file transfers with PDF files of varying sizes: **0.5 MB, 1 MB, 2 MB, 4 MB,** and **10 MB**. Two key scenarios are tested:

- **Single-threaded operations**: A single file is uploaded or downloaded at a time, providing insight into sequential performance.
- **Multi-threaded operations**: 10 files are transferred in parallel, measuring how well our infrastructure implementation handles concurrent operations.

Each test is executed **50 times** to ensure robust statistical data, minimizing the impact of fluctuations. The tool then compiles and generates comprehensive statistics.

### Results
