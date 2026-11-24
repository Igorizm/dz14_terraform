locals {
  vms = {
    build = { name = "build-vm" }
    prod  = { name = "prod-vm" }
  }
}

data "cloudru_evolution_compute_image_collection" "ubuntu" {
  project_id = var.project_id
  page_size  = 100
}

# --- Группа безопасности (общая) ---
resource "cloudru_evolution_compute_security_group" "hw" {
  project_id  = var.project_id
  name        = "hw-sg"
  zone        = { name = var.zone }
  description = "Группа безопасности учебных ВМ"
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_ssh" {
  security_group_id = cloudru_evolution_compute_security_group.hw.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "22:22"
  description       = "SSH"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "ingress_app" {
  security_group_id = cloudru_evolution_compute_security_group.hw.id
  direction         = "TRAFFIC_DIRECTION_INGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "8080:8080"
  description       = "Java-приложение"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "egress_all" {
  security_group_id = cloudru_evolution_compute_security_group.hw.id
  direction         = "TRAFFIC_DIRECTION_EGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_TCP"
  port_range        = "1:65535"
  description       = "Весь исходящий TCP"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "cloudru_evolution_compute_security_group_rule" "egress_dns" {
  security_group_id = cloudru_evolution_compute_security_group.hw.id
  direction         = "TRAFFIC_DIRECTION_EGRESS"
  ether_type        = "ETHER_TYPE_IPV4"
  ip_protocol       = "IP_PROTOCOL_UDP"
  port_range        = "53:53"
  description       = "Исходящий DNS (UDP)"
  remote_ip_prefix  = "0.0.0.0/0"
}

# --- Публичные IP ---
resource "cloudru_evolution_compute_external_ip" "vm" {
  for_each   = local.vms
  name       = "${each.key}-ext-ip"
  project_id = var.project_id
  zone       = { name = var.zone }
}

# --- Диски ---
resource "cloudru_evolution_compute_disk" "vm" {
  for_each   = local.vms
  project_id = var.project_id
  name       = "${each.key}-disk"
  size       = var.disk_size
  zone       = { name = var.zone }
  disk_type  = { name = "SSD" }
  bootable   = true
  image      = { id = [for img in data.cloudru_evolution_compute_image_collection.ubuntu.images : img.id if img.name == "ubuntu-22.04"][0] }
  encrypted  = false
  readonly   = false
  shared     = false
}

# --- Интерфейсы в рабочей подсети 10.0.1.0/24 ---
resource "cloudru_evolution_compute_interface" "vm" {
  for_each                   = local.vms
  project_id                 = var.project_id
  name                       = "${each.key}-iface"
  zone                       = { name = var.zone }
  description                = "Сетевой интерфейс ${each.key}"
  subnet                     = { id = "9006484c-07a0-4705-a563-f8caa4acc519" }
  security_groups            = [{ id = cloudru_evolution_compute_security_group.hw.id }]
  interface_security_enabled = true
  type                       = "INTERFACE_TYPE_REGULAR"

  attach_external_ip = { id = cloudru_evolution_compute_external_ip.vm[each.key].id }
}

# --- Виртуальные машины ---
resource "cloudru_evolution_compute_vm" "vm" {
  for_each            = local.vms
  project_id          = var.project_id
  name                = each.value.name
  zone                = { name = var.zone }
  flavor              = { name = var.flavor }
  description         = "ВМ ${each.key} из ДЗ по Terraform"
  disks               = [{ id = cloudru_evolution_compute_disk.vm[each.key].id }]
  network_interfaces  = [{ id = cloudru_evolution_compute_interface.vm[each.key].id }]
  cloud_init_userdata = base64encode(templatefile("${path.module}/cloud-init.yaml.tpl", {
    ssh_public_key = file("~/.ssh/id_ed25519.pub")
    vm_name        = each.value.name
  }))
}

output "build_vm_ip" {
  value = cloudru_evolution_compute_interface.vm["build"].attach_external_ip.ip_address
}

output "prod_vm_ip" {
  value = cloudru_evolution_compute_interface.vm["prod"].attach_external_ip.ip_address
}
