# Terraform AKS Cluster with Multiple Node Pools

 
This Terraform code provisions an AKS cluster with multiple node pools and configures its network profile, default node pool, and node pools for analyzer, clickhouse, and cs. It also provisions a virtual network with multiple subnets.

## Usage

To use this Terraform code:

1. Install Terraform on your machine.
2. Clone this repository.
3. Navigate to the cloned directory.
4. Run `terraform init` to initialize the Terraform configuration.
5. Run `terraform plan` to see the infrastructure plan.
6. Run `terraform apply` to apply the infrastructure changes.

## AKS Cluster

The AKS cluster is created with the provided parameters, such as the name, location, and Kubernetes version. The network profile is configured to use Azure CNI as the network plugin with the Overlay mode and Cilium as the eBPF dataplane. A pod CIDR of 192.168.0.0/16 is also configured.

The default node pool is created with the provided parameters, such as the name, minimum and maximum count of nodes, VM size, and tags. It is configured to use the core subnet.

Three additional node pools are also created, one for the analyzer, one for ClickHouse, and one for CS, with similar configurations to the default node pool.

## Virtual Network

Finally, a virtual network with five subnets is created, named core, ep, nat, public, and site, with the provided CIDR blocks.

Note that the commented-out code for the container registry is not used in this configuration.
