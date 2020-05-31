variable "hetzner_cloud_token" {
  description = "The Hetzner Cloud API Token"
  type        = string
}

//
// General settings
//
variable "private_network_range" {
  description = "Private network range"
  type        = string
  default     = "10.0.0.0/8"
}

variable "private_network_name" {
  description = "The name of the private network"
  type        = string
  default     = "consul-nomad"
}

//
// Nomad server settings
//
variable "nomad_server_name_format" {
  description = "The name format of the nomad servers"
  type        = string
  default     = "nomad-server-%s"
}

variable "nomad_server_count" {
  description = "The number of nomad servers to provision"
  type        = number
  default     = 3
}

variable "nomad_server_type" {
  description = "The type of machine to use for the nomad servers"
  type        = string
  default     = "cpx11"
}

variable "nomad_server_image" {
  description = "The image to use for the nomad servers"
  type        = string
  default     = "ubuntu-18.04"
}

variable "nomad_server_location" {
  description = "The Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

variable "nomad_server_ssh_keys" {
  description = "The IDs of the ssh keys to be used for the nomad servers."
  type        = list(string)
  default     = []
}

//
// Nomad client settings
//
variable "nomad_client_name_format" {
  description = "The name format of the nomad clients"
  type        = string
  default     = "nomad-client-%s"
}

variable "nomad_client_count" {
  description = "The number of nomad clients to provision"
  type        = number
  default     = 3
}

variable "nomad_client_type" {
  description = "The type of machine to use for the nomad clients"
  type        = string
  default     = "cpx31"
}

variable "nomad_client_image" {
  description = "The image to use for the nomad clients"
  type        = string
  default     = "ubuntu-18.04"
}

variable "nomad_client_location" {
  description = "The Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

variable "nomad_client_ssh_keys" {
  description = "The IDs of the ssh keys to be used for the nomad clients."
  type        = list(string)
  default     = []
}

//
// Consul server settings
//
variable "consul_server_name_format" {
  description = "The name format of the consul servers"
  type        = string
  default     = "consul-server-%s"
}

variable "consul_server_count" {
  description = "The number of consul servers to provision"
  type        = number
  default     = 3
}

variable "consul_server_type" {
  description = "The type of machine to use for the consul servers"
  type        = string
  default     = "cx11"
}

variable "consul_server_image" {
  description = "The image to use for the consul servers"
  type        = string
  default     = "ubuntu-18.04"
}

variable "consul_server_location" {
  description = "The Hetzner datacenter location"
  type        = string
  default     = "nbg1"
}

variable "consul_server_ssh_keys" {
  description = "The IDs of the ssh keys to be used for the consul servers."
  type        = list(string)
  default     = []
}

provider "hcloud" {
  token = var.hetzner_cloud_token
}

resource "hcloud_network" "private-network" {
  name     = var.private_network_name
  ip_range = var.private_network_range
}

resource "hcloud_network_subnet" "consul-server" {
  network_id   = hcloud_network.private-network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_network_subnet" "nomad-server" {
  network_id   = hcloud_network.private-network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_network_subnet" "nomad-client" {
  network_id   = hcloud_network.private-network.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.0.2.0/24"
}

resource "hcloud_server" "consul-server" {
  image       = var.consul_server_image
  name        = format(var.consul_server_name_format, count.index + 1)
  server_type = var.consul_server_type
  count       = var.consul_server_count
  ssh_keys    = var.consul_server_ssh_keys
  location    = var.consul_server_location
  labels = {
    service : "consul-server"
  }
}

resource "hcloud_server" "nomad-server" {
  image       = var.nomad_server_image
  name        = format(var.nomad_server_name_format, count.index + 1)
  server_type = var.nomad_server_type
  count       = var.nomad_server_count
  ssh_keys    = var.nomad_server_ssh_keys
  location    = var.nomad_server_location
  labels = {
    service : "nomad-server"
  }
}

resource "hcloud_server" "nomad-client" {
  image       = var.nomad_client_image
  name        = format(var.nomad_client_name_format, count.index + 1)
  server_type = var.nomad_client_type
  count       = var.nomad_client_count
  ssh_keys    = var.nomad_client_ssh_keys
  location    = var.nomad_client_location
  labels = {
    service : "nomad-client"
  }
}

resource "hcloud_server_network" "consul-server" {
  network_id = hcloud_network.private-network.id
  server_id  = element(hcloud_server.consul-server.*.id, count.index)
  count      = var.consul_server_count
  ip         = cidrhost(hcloud_network_subnet.consul-server.ip_range, count.index + 2)
}

resource "hcloud_server_network" "nomad-server" {
  network_id = hcloud_network.private-network.id
  server_id  = element(hcloud_server.nomad-server.*.id, count.index)
  count      = var.nomad_server_count
  ip         = cidrhost(hcloud_network_subnet.nomad-server.ip_range, count.index + 2)
}

resource "hcloud_server_network" "nomad-client" {
  network_id = hcloud_network.private-network.id
  server_id  = element(hcloud_server.nomad-client.*.id, count.index)
  count      = var.nomad_client_count
  ip         = cidrhost(hcloud_network_subnet.nomad-client.ip_range, count.index + 2)
}

resource "hcloud_floating_ip" "nomad-client" {
  type          = "ipv4"
  server_id     = hcloud_server.nomad-client[0].id
  home_location = "nbg1"
}

resource "hcloud_volume" "portworx" {
  count      = length(hcloud_server.nomad-client)
  name       = "portworx-${count.index + 1}"
  location   = "nbg1"
  size       = 10
  depends_on = [hcloud_server.nomad-client]
}

resource "hcloud_volume_attachment" "portworx" {
  count      = length(hcloud_volume.portworx)
  volume_id  = element(hcloud_volume.portworx.*.id, count.index)
  server_id  = element(hcloud_server.nomad-client.*.id, count.index)
  depends_on = [hcloud_volume.portworx]
}

locals {
  nomad_client_load_balancer = zipmap(hcloud_floating_ip.nomad-client[*].server_id, hcloud_floating_ip.nomad-client[*].ip_address)

  ansible_inventory = templatefile("${path.module}/templates/ansible/inventory.tmpl", {
    consul_servers = flatten([
      for s in hcloud_server.consul-server : [
        for p in hcloud_server_network.consul-server : {
          public  = s.ipv4_address,
          private = p.ip,
        } if tostring(p.server_id) == tostring(s.id)
      ]
    ])

    nomad_servers = flatten([
      for s in hcloud_server.nomad-server : [
        for p in hcloud_server_network.nomad-server : {
          public  = s.ipv4_address,
          private = p.ip,
        } if tostring(p.server_id) == tostring(s.id)
      ]
    ])

    nomad_clients = flatten([
      for s in hcloud_server.nomad-client : [
        for p in hcloud_server_network.nomad-client : {
          public   = s.ipv4_address,
          private  = p.ip,
          floating = contains(keys(local.nomad_client_load_balancer), s.id) ? local.nomad_client_load_balancer[s.id] : "",
        } if tostring(p.server_id) == tostring(s.id)
      ]
    ])
  })
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/build/ansible/inventory/hetzner"
  content  = local.ansible_inventory
}

output "ansible_inventory" {
  value = local.ansible_inventory
}
