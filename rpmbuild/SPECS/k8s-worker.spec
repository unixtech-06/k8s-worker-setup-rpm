Name:           k8s-worker
Version:        1.43
Release:        1%{?dist}
Summary:        One-shot setup for Kubernetes worker (no rpm-in-rpm)
License:        MIT
URL:            https://example.local/k8s-worker
BuildArch:      noarch

Source0:        prepare-worker.sh
Source1:        finalize.sh
Source2:        k8s-worker-finalize.service
Source3:        k8s-worker-finalize.timer

BuildRequires:  systemd-rpm-macros
Requires(post): systemd, bash, coreutils, sed, grep, procps-ng, policycoreutils, kmod, firewalld
Requires:       dnf  

%description
Configures kernel/sysctl/SELinux/firewalld. Avoids running dnf inside scriptlets.
Installs containerd/kubelet via a systemd timer after the rpm transaction.

%prep
%setup -c -T
cp -p %{SOURCE0} .
cp -p %{SOURCE1} .
cp -p %{SOURCE2} .
cp -p %{SOURCE3} .

%build
# none

%install
rm -rf %{buildroot}
install -Dpm0755 prepare-worker.sh %{buildroot}%{_libexecdir}/k8s-worker/prepare-worker.sh
install -Dpm0755 finalize.sh      %{buildroot}%{_libexecdir}/k8s-worker/finalize.sh
install -Dpm0644 k8s-worker-finalize.service %{buildroot}%{_unitdir}/k8s-worker-finalize.service
install -Dpm0644 k8s-worker-finalize.timer   %{buildroot}%{_unitdir}/k8s-worker-finalize.timer

%post
# 設定（swap/SELinux/firewalld/sysctl/k8s repo）だけ実行
/usr/libexec/k8s-worker/prepare-worker.sh 2>&1 | tee -a /var/log/k8s-worker-setup.log || :
# タイマーを有効化＆起動（実処理はトランザクション後に実行される）
%systemd_post k8s-worker-finalize.timer
systemctl start k8s-worker-finalize.timer >/dev/null 2>&1 || :

%preun
%systemd_preun k8s-worker-finalize.timer

%postun
%systemd_postun_with_restart k8s-worker-finalize.timer

%files
%{_libexecdir}/k8s-worker/prepare-worker.sh
%{_libexecdir}/k8s-worker/finalize.sh
%{_unitdir}/k8s-worker-finalize.service
%{_unitdir}/k8s-worker-finalize.timer

%changelog
* Thu Dec 25 2025 Ryosuke Nakayama <ryosuke_666@icloud.com> 1.43-1
- Update Kubernetes release to v1.35
