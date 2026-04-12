!#/bin/bash

set -e

echo "No dev tools listed in RHEL 8"

dnf update -y && dnf upgrade -y
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf install -y 'dnf-command(config-manager)'
dnf config-manager --add-repo https://mirror.stream.centos.org/8-stream/BaseOS/x86_64/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/8-stream/AppStream/x86_64/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/8-stream/CRB/x86_64/os/
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf makecache
rpm -e --nodeps openssl-fips-provider-so || true
dnf update -y --allowerasing