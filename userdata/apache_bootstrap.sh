#!/bin/bash
set -euxo pipefail

# For AL2023
dnf -y update || true
dnf -y install httpd

cat >/var/www/html/index.html <<'HTML'
<!doctype html>
<html><head><title>POC</title></head>
<body>
<h1>Coalfire POC — App Tier</h1>
</body></html>
HTML

systemctl enable httpd
systemctl start httpd
