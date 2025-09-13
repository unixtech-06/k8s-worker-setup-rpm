# k8s-worker-setup (RPM)

Kubernetes ワーカーノード用の初期設定（swap 無効化 / SELinux permissive / firewalld / sysctl / containerd / kubelet 等）を **1コマンド導入**できる RPM。

---

## 0) ホスト名を決める
例：`k8s-worker01`（`k8s-worker{n}` のつもりで連番に）
```bash
sudo hostnamectl set-hostname "k8s-worker01" && exec bash
```

## 1) RPMをビルドする
```bash
# ビルドツール
sudo dnf -y install rpm-build rpmdevtools

# 標準ツリー作成
rpmdev-setuptree

# （このリポジトリのルートで）
cp -a ./SOURCES/*  ~/rpmbuild/SOURCES/
cp -a ./SPECS/*    ~/rpmbuild/SPECS/

# ビルド
rpmbuild -ba ~/rpmbuild/SPECS/k8s-worker.spec
```

## 2) dnf でインストールする
```bash
# 生成された noarch RPM をローカルからインストール
sudo dnf -y install ~/rpmbuild/RPMS/noarch/k8s-worker-*.noarch.rpm
```
もし既存の kubernetes.repo が壊れていて dnf がコケる場合は、いったん無効化してからインストールしてください：
```bash
sudo dnf -y --disablerepo=kubernetes install ~/rpmbuild/RPMS/noarch/k8s-worker-*.noarch.rpm
```

## 3)（任意）状態確認
```bash
# 後処理タイマー（containerd / kubelet 導入）確認
systemctl status k8s-worker-finalize.timer
journalctl -u k8s-worker-finalize.service -n 100 --no-pager

# コマンド確認
containerd --version
kubelet --version
kubeadm version
```
