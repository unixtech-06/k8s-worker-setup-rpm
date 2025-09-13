#!/usr/bin/bash
set -Euo pipefail
log(){ echo "[k8s-worker] $*"; }

disable_swap(){
  log "Disable swap"
  swapoff -a || true
  sed -i '/[[:space:]]swap[[:space:]]/ s/^\(.*\)$/#\1/g' /etc/fstab || true
}

set_selinux_perm(){
  if command -v getenforce >/dev/null 2>&1; then setenforce 0 || true; fi
  for cfg in /etc/selinux/config /etc/sysconfig/selinux; do
    [ -f "$cfg" ] && sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=permissive/g' "$cfg" || true
  done
}

open_firewall(){
  if ! command -v firewall-cmd >/dev/null 2>&1; then return 0; fi
  firewall-cmd --permanent --add-port=179/tcp      || true
  firewall-cmd --permanent --add-port=10250/tcp    || true
  firewall-cmd --permanent --add-port=30000-32767/tcp || true
  firewall-cmd --permanent --add-port=4789/udp     || true
  firewall-cmd --reload || true
}

kernel_and_sysctl(){
  install -D -m 0644 /dev/null /etc/modules-load.d/containerd.conf
  printf "overlay\nbr_netfilter\n" > /etc/modules-load.d/containerd.conf
  modprobe overlay || true; modprobe br_netfilter || true
  install -D -m 0644 /dev/null /etc/sysctl.d/k8s.conf
  cat >/etc/sysctl.d/k8s.conf <<'EOT'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOT
  sysctl --system || true
}

# ここでは Kubernetes repo だけ置く（バージョンは環境変数で切替可能）
write_k8s_repo(){
  local series="${K8S_SERIES:-v1.34}"
  cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${series}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${series}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
}

main(){
  disable_swap
  set_selinux_perm
  open_firewall
  kernel_and_sysctl
  write_k8s_repo
  log "prepare done"
}
main "$@"

