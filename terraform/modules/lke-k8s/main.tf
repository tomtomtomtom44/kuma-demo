//Use the Linode Provider
provider "linode" {
  token = var.token
}

resource "linode_lke_cluster" "main" {
  k8s_version = var.lke_cluster_k8s_version
  label       = var.lke_cluster_label
  region      = var.lke_cluster_region
  tags      = var.tags

  control_plane {

      acl {
        addresses {
                ipv4 = ["${var.ipv4}/32"]
                ipv6 = [length(regexall("/", var.ipv6)) > 0 ? var.ipv6 : "${var.ipv6}/128"]
            }
        enabled = true
      }
  }

  dynamic "pool" {
        for_each = var.pools
        content {
            type  = pool.value["type"]
            count = pool.value["count"]
        }
    }
}

resource "linode_firewall" "lke_firewall" {
  label = "${var.lke_cluster_label}-nodes-fw"
  tags  = var.tags

  inbound_policy = "DROP" 
  outbound_policy = "ACCEPT"

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["${var.ipv4}/32"]
    ipv6     = [length(regexall("/", var.ipv6)) > 0 ? var.ipv6 : "${var.ipv6}/128"]
  }

  inbound {
    label     = "allow-k8s-tcp"
    action    = "ACCEPT"
    protocol  = "TCP"
    ports     = "1-65535"
    ipv4     = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  }

  inbound {
    label     = "allow-k8s-udp"
    action    = "ACCEPT"
    protocol  = "UDP"
    ports     = "1-65535"
    ipv4     = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  }

  inbound {
    label     = "allow-k8s-icmp"
    action    = "ACCEPT"
    protocol  = "ICMP"
    ipv4     = ["10.0.0.0/8", "192.168.0.0/16", "172.16.0.0/12"]
  }

  inbound {
    label    = "allow-apiserver-to-webhooks-tcp"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80, 443, 10250"
    ipv4     = ["0.0.0.0/0"] # TEMP: replace with control-plane CIDRs when known
    ipv6     = ["::/0"]
  }
  
  linodes = flatten([for p in linode_lke_cluster.main.pool : p.nodes[*].instance_id])
}
