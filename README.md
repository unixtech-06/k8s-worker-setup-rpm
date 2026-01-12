# k8s-worker-setup (RPM)

Kubernetes ワーカーノード用の初期設定（swap 無効化 / SELinux permissive / firewalld / sysctl / containerd / kubelet 等）を **1コマンド導入**できる RPM。

---

## 0) ホスト名を決める
例：`k8s-worker01`（`k8s-worker{n}` のつもりで連番に）
```bash
sudo hostnamectl set-hostname "k8s-worker01" && exec bash
```

## 1) DNFリポジトリからインストール（推奨）

```bash
# リポジトリ追加
sudo curl -o /etc/yum.repos.d/k8s-worker.repo \
  https://ryskn.github.io/k8s-worker-setup-rpm/k8s-worker.repo

# インストール
sudo dnf -y install k8s-worker
```

> EL9/EL10 両方に対応しています。

## 2)（任意）状態確認
```bash
# 後処理タイマー（containerd / kubelet 導入）確認
systemctl status k8s-worker-finalize.timer
journalctl -u k8s-worker-finalize.service -n 100 --no-pager

# コマンド確認
containerd --version
kubelet --version
kubeadm version
```

---

## 付録: 手動でRPMをビルドする

```bash
# ビルドツール
sudo dnf -y install rpm-build rpmdevtools

# 標準ツリー作成
rpmdev-setuptree

# （このリポジトリのルートで）
cp -a ./rpmbuild/SOURCES/*  ~/rpmbuild/SOURCES/
cp -a ./rpmbuild/SPECS/*    ~/rpmbuild/SPECS/

# ビルド
rpmbuild -ba ~/rpmbuild/SPECS/k8s-worker.spec

# インストール
sudo dnf -y install ~/rpmbuild/RPMS/noarch/k8s-worker-*.noarch.rpm
```
