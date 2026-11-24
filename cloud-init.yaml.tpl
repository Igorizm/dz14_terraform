#cloud-config
hostname: ${vm_name}
manage_etc_hosts: true
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false
    passwd: "$6$zkCQcqRZPrsZ.bA.$q74yUrBQsa.ea5lQYYg0n23ZSkBZn4GG9MIC36M9blWHKbvADUZ39CIkncTF2GeH2ZMZyHLP2nGFE54seaKBF0"
    ssh_authorized_keys:
      - ${ssh_public_key}
ssh_pwauth: true
chpasswd:
  expire: false
runcmd:
  - systemctl enable --now ssh
