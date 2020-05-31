
<div align="center">
<img src="./terraform.png">
<br><br>

![Terraform](https://github.com/ThePixelDeveloper/terraform/workflows/Terraform/badge.svg?branch=master)
</div>

----

## Features

* Infrastructure for a fault tolerant [Nomad](https://www.nomadproject.io/) (alternative job scheduler to Kubernetes) cluster.

## What?

This repository contains the code to spin up [Consul](https://www.consul.io/)
and [Nomad](https://www.nomadproject.io/) servers and clients, ready to be provisioned by
Ansible. Without this project I'd have to manually create these machines on Hetzner
Cloud, a time consuming process.

We default to having three servers in the cluster, meaning the platform can
survive with a server going down.


## Setup

1. Rename `backend.hcl.example` to `backend.hcl` and fill in with your Terraform Cloud values.
2. Rename `terraform.tfvars.example` to `terraform.tfvars` and fill in with your Hetzner Cloud values.
3. Run `terraform init -backend-config=backend.hcl`
4. Run `terraform plan` to see what's going to happen.
5. Run `terraform apply` to apply changes.

## Variables

### General
| Name  | Default | Description |
|---|---|---|
| hetzner_cloud_token | | The Hetzner Cloud API Token |
| private_network_range | 10.0.0.0/8 | Private network range |
| private_network_name | consul-nomad | The name of the private network |

### Consul Server
| Name  | Default | Description |
|---|---|---|
| consul_server_name_format | consul-server-%s | The name format of the consul servers |
| consul_server_count | 3 | The number of consul servers to provision |
| consul_server_type | cx11 | The type of machine to use for the consul servers |
| consul_server_image | ubuntu-18.04 | The image to use for the consul servers |
| consul_server_location | nbg1 | The Hetzner datacenter location |
| consul_server_ssh_keys | [] | The IDs of the ssh keys to be used for the consul servers. |

### Nomad Server
| Name  | Default | Description |
|---|---|---|
| nomad_server_name_format | nomad-server-%s | The name format of the nomad servers |
| nomad_server_count | 3 | The number of nomad servers to provision |
| nomad_server_type | cpx11 | The type of machine to use for the nomad servers |
| nomad_server_image | ubuntu-18.04 | The image to use for the nomad servers |
| nomad_server_location | nbg1 | The Hetzner datacenter location |
| nomad_server_ssh_keys | [] | The IDs of the ssh keys to be used for the nomad servers. |

### Nomad Client
| Name  | Default | Description |
|---|---|---|
| nomad_client_name_format | nomad-client-%s | The name format of the nomad clients |
| nomad_client_count | 3 | The number of nomad clients to provision |
| nomad_client_type | cpx31 | The type of machine to use for the nomad clients |
| nomad_client_image | ubuntu-18.04 | The image to use for the nomad clients |
| nomad_client_location | nbg1 | The Hetzner datacenter location |
| nomad_client_ssh_keys | [] | The IDs of the ssh keys to be used for the nomad clients. |

## Output

We output an Ansible inventory file to `./build/ansible/inventory/hetzner`.
``` ini
[consul_server]
... ipv4_address_private=10.0.0.2
... ipv4_address_private=10.0.0.3
... ipv4_address_private=10.0.0.4

[nomad_server]
... ipv4_address_private=10.0.1.2
... ipv4_address_private=10.0.1.3
... ipv4_address_private=10.0.1.4

[consul_client]
... ipv4_address_private=10.0.1.2
... ipv4_address_private=10.0.1.3
... ipv4_address_private=10.0.1.4
... ipv4_address_private=10.0.2.2
... ipv4_address_private=10.0.2.3
... ipv4_address_private=10.0.2.4

[nomad_client]
... ipv4_address_private=10.0.2.2 ipv4_address_floating=...
... ipv4_address_private=10.0.2.3 
... ipv4_address_private=10.0.2.4 
```
