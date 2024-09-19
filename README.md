# Multi-client file share

## Introduction

    The goal of this PoC is to showcase how to setup a high-performance cross-regional fileshare. 

## Prerequisites

   - Terraform
   - Azure CLI
   - Powershell

## Architecture Diagram

![](./architecture.drawio.png)

## IaC approach
    
    We are using Terraform for our IaC strategy. The goal is to create a modularized, secure deployment

## Resource Definitions

    VM-Clients
    - VMs running with windows server, datacenter editio 2022. 
    - VMs can be replicated however often is required
    - Extensions are used, to ensure the mounting process & dependency management is run for each deployment
    - Accesable with RDP

    Storageaccount:
    - Standard storage account
    - Has a file share, which we later mount to the VMs
    - Private link to ensure security

    Keyvault: 
    -  Contains any secrets that we need along the way

    VNET:
    - We have two VNETs, one for each region. 
    - VNETs are peered with each other
    - We manage the firewall using SecurityGroups on the VNET level.
    

## Networking and Connectivity

    Peering/VPN: Provide detailed steps on setting up VNet peering (or a VPN) to ensure the VMs in the US can communicate with the file share in Europe.
    DNS Resolution: Describe how DNS will resolve the file share’s address from the VMs in the US.
    Latency Considerations: Address any cross-region latency issues that might affect the mounting of the file share.

##  Benchmarking & Testing

    Mounting File Share: Provide detailed steps on how to mount the file share on the VMs, including any necessary credentials or commands.
    File Share Access: Explain how to test that the VMs can successfully read/write to the file share.
    Connectivity Testing: Provide steps for testing cross-region connectivity (e.g., ping, traceroute, etc.).

##  Troubleshooting

    Common Issues: List potential issues like peering misconfigurations, file share mounting issues, or firewall blocking, and provide solutions.
    Logs & Debugging: Include information on where to find logs and how to debug Terraform deployment errors or connectivity problems.

## Conclusion

    Summary of Setup: Recap the infrastructure deployed and its success.
    Next Steps: Mention any future enhancements (e.g., setting up monitoring, scaling the solution, etc.).

## Ansible playbook configuration

Due to the short notice of the request, we were unable to implement Ansible playbooks as initially planned. The limited time available did not allow for the development, testing, and fine-tuning of Ansible configurations. Instead, we opted for Terraform, which allowed us to quickly provision and configure the required infrastructure in a more time-efficient manner, leveraging its declarative approach and our team's familiarity with the tool. This ensured that we met the deadline while maintaining the desired configuration outcomes.

## Performance measurement report

The project under `src/Benchmark` is designed to evaluate the performance of the Azure File Share by benchmarking file upload and download operations. The benchmarking is implemented using a .NET-based tool in conjunction with the BenchmarkDotNet library, providing detailed insights into the performance characteristics under different conditions.

### Benchmarking approach

The tool measures the performance of file transfers with PDF files of varying sizes: **0.5 MB, 1 MB, 2 MB, 4 MB,** and **10 MB**. Two key scenarios are tested:

- **Single-threaded operations**: A single file is uploaded or downloaded at a time, providing insight into sequential performance.
- **Multi-threaded operations**: 10 files are transferred in parallel, measuring how well our infrastructure implementation handles concurrent operations.

Each test is executed **50 times** to ensure robust statistical data, minimizing the impact of fluctuations. The tool then compiles and generates comprehensive statistics.

### Results
