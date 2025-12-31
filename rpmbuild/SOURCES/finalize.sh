#!/usr/bin/bash
set -Euo pipefail
LOG=/var/log/k8s-worker-finalize.log
STAMP=/var/lib/k8s-worker/finalized
mkdir -p "$(dirname "$LOG")" "$(dirname "$STAMP")"

log(){ echo "[k8s-worker-finalize] $*" | tee -a "$LOG"; }

# 既に完了していたら何もしない
[ -f "$STAMP" ] && { log "already finalized"; exit 0; }

# ネット待ち（最大60秒）
for i in {1..30}; do
  ping -c1 -W1 8.8.8.8 >/dev/null 2>&1 && break
  sleep 2
done

# containerd を distro から優先インストール。無ければ Docker repo を追加
if ! command -v containerd >/dev/null 2>&1; then
  log "install containerd"
  if ! dnf -y install containerd; then
    dnf -y install dnf-plugins-core || true
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
    rpm --import https://download.docker.com/linux/centos/gpg || true
    dnf -y install containerd.io
  fi
  mkdir -p /etc/containerd
  containerd config default >/etc/containerd/config.toml 2>/dev/null || true
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true
  systemctl enable --now containerd || true
fi

# Kubernetes ツール
release="${K8S_RELEASE:-v1.35}"
rpm --import "https://pkgs.k8s.io/core:/stable:/${release}/rpm/repodata/repomd.xml.key" || true
dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes || true
systemctl enable --now kubelet || true

touch "$STAMP"
log "finalize done"
exit 0

