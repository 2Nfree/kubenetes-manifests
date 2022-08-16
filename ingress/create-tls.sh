kubectl -n ingress-nginx create secret tls ceph-tls \
  --cert=证书路径 \
  --key=证书私钥路径
