Name:           selfsign
Version:        1.0
Release:        1%{?dist}
Summary:        A tool for generating self-signed certificates

Group:          TecAdmin
BuildArch:      noarch
License:        GPL
URL:            https://github.com/mpotra/selfsign.git
Source0:        %{name}-%{version}.tar.gz

Requires:       openssl

%description
A tool for generating self-signed certificates, including CA and Intermediate certificates.

%prep
%setup -q

%build
awk -v repl="SELFSIGN_INSTALL_DIR=%{_sharedstatedir}/selfsign" '{gsub(/\SELFSIGN_INSTALL_DIR=\./,repl); print }' selfsign.sh > selfsign-dist.sh
awk -v repl="SELFSIGN_INSTALL_DIR=%{_sharedstatedir}/selfsign" '{gsub(/\SELFSIGN_INSTALL_DIR=\./,repl); print }' selfsign-ca.sh > selfsign-ca-dist.sh
awk -v repl="%{_sharedstatedir}/selfsign/ca" '{gsub(/\$INSTALL_PATH/,repl); print }' ca/openssl-template.cnf > ca/openssl.cnf
awk -v repl="%{_sharedstatedir}/selfsign/ca/intermediate" '{gsub(/\$INSTALL_PATH/,repl); print }' ca/intermediate/openssl-template.cnf > ca/intermediate/openssl.cnf

%install
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
install -m 0755 selfsign-dist.sh $RPM_BUILD_ROOT/%{_bindir}/selfsign
install -m 0755 selfsign-ca-dist.sh $RPM_BUILD_ROOT/%{_bindir}/selfsign-ca
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca
install --directory -m 0755 $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/certs
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/crl
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/csr
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/newcerts
install --directory -m 0755 $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/private
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate
install --directory -m 0755 $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/certs
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/crl
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/csr
install --directory $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/newcerts
install --directory -m 0755 $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/private
chmod -R 755 $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign
install -m 0600 ca/openssl.cnf $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/openssl.cnf
install -m 0600 ca/index.txt $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/index.txt
install -m 0600 ca/serial $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/serial
install -m 0600 ca/intermediate/openssl.cnf $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/openssl.cnf
install -m 0600 ca/intermediate/index.txt $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/index.txt
install -m 0600 ca/intermediate/serial $RPM_BUILD_ROOT/%{_sharedstatedir}/selfsign/ca/intermediate/serial

%files
/%{_bindir}/selfsign
/%{_bindir}/selfsign-ca
%dir /%{_sharedstatedir}/selfsign/ca
%dir /%{_sharedstatedir}/selfsign/ca/certs
%dir /%{_sharedstatedir}/selfsign/ca/private
%dir /%{_sharedstatedir}/selfsign/ca/newcerts
%dir /%{_sharedstatedir}/selfsign/ca/csr
%dir /%{_sharedstatedir}/selfsign/ca/crl
%dir /%{_sharedstatedir}/selfsign/ca/intermediate
%dir /%{_sharedstatedir}/selfsign/ca/intermediate/certs
%dir /%{_sharedstatedir}/selfsign/ca/intermediate/private
%dir /%{_sharedstatedir}/selfsign/ca/intermediate/csr
%dir /%{_sharedstatedir}/selfsign/ca/intermediate/newcerts
%dir /%{_sharedstatedir}/selfsign/ca/intermediate/crl
/%{_sharedstatedir}/selfsign/ca/openssl.cnf
/%{_sharedstatedir}/selfsign/ca/intermediate/openssl.cnf
/%{_sharedstatedir}/selfsign/ca/index.txt
/%{_sharedstatedir}/selfsign/ca/serial
/%{_sharedstatedir}/selfsign/ca/intermediate/index.txt
/%{_sharedstatedir}/selfsign/ca/intermediate/serial


%changelog
* Wed Nov 16 2022 Mihai Potra <mike@mpotra.com> - 1.0
  - First version release
