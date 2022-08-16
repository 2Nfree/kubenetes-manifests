# 如何使用

## 修改部分存储类名称
- prometheus/grafana/grafana-pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-storage
  namespace: monitoring
  labels:
    app: grafana-storage
spec:
  storageClassName: 【存储类名称】
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 30Gi
```
- prometheus/prometheus/prometheus-prometheus.yaml
```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.32.1
  name: k8s
  namespace: monitoring
spec:
  alerting:
    alertmanagers:
    - apiVersion: v2
      name: alertmanager-main
      namespace: monitoring
      port: web
  enableFeatures: []
  externalLabels: {}
  image: quay.io/prometheus/prometheus:v2.32.1
  nodeSelector:
    kubernetes.io/os: linux
  podMetadata:
    labels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
      app.kubernetes.io/version: 2.32.1
  podMonitorNamespaceSelector: {}
  podMonitorSelector: {}
  probeNamespaceSelector: {}
  probeSelector: {}
  replicas: 2
  resources:
    requests:
      memory: 400Mi
  ruleNamespaceSelector: {}
  ruleSelector: {}
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  serviceAccountName: prometheus-k8s
  serviceMonitorNamespaceSelector: {}
  serviceMonitorSelector: {}
  version: 2.32.1
  storage: 
    volumeClaimTemplate:
      metadata: 
        name: prometheus-k8s-db
      spec:
        accessModes:
        - ReadWriteMany
        storageClassName: 【存储类名称】
        resources:
          requests:
            storage: 50Gi
```
- prometheus/alertmanager/alertmanager-alertmanager.yaml
```yaml
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  labels:
    app.kubernetes.io/component: alert-router
    app.kubernetes.io/instance: main
    app.kubernetes.io/name: alertmanager
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 0.23.0
  name: main
  namespace: monitoring
spec:
  image: quay.mirrors.ustc.edu.cn/prometheus/alertmanager:v0.23.0
  nodeSelector:
    kubernetes.io/os: linux
  podMetadata:
    labels:
      app.kubernetes.io/component: alert-router
      app.kubernetes.io/instance: main
      app.kubernetes.io/name: alertmanager
      app.kubernetes.io/part-of: kube-prometheus
      app.kubernetes.io/version: 0.23.0
  replicas: 3
  resources:
    limits:
      cpu: 100m
      memory: 100Mi
    requests:
      cpu: 4m
      memory: 100Mi
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  serviceAccountName: alertmanager-main
  version: 0.23.0
  storage:
    volumeClaimTemplate:
      metadata:
        name: alertmanager-main-db
      spec:
        accessModes:
        - ReadWriteMany
        storageClassName: 【存储类名称】
        resources:
          requests:
            storage: 10Gi
```
## 国内需要修改镜像地址
```bash
#查看镜像地址
cat images.txt

quay.io/prometheus/node-exporter:v1.3.1
quay.io/prometheus/prometheus:v2.32.1
quay.io/prometheus/alertmanager:v0.23.0
quay.io/prometheus/blackbox-exporter:v0.19.0
quay.io/brancz/kube-rbac-proxy:v0.11.0
quay.io/prometheus-operator/prometheus-operator:v0.53.1


k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.3.0
k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1

jimmidyson/configmap-reload:v0.5.0

grafana/grafana:8.3.10
```
其中
- quay.io替换成quay.mirrors.ustc.edu.cn
- k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.3.0、k8s.gcr.io/prometheus-adapter/prometheus-adapter:v0.9.1需要手动导入镜像
- grafana/grafana:8.3.10、jimmidyson/configmap-reload:v0.5.0可直接国内网络下载
```bash
#quay.io替换quay.mirrors.ustc.edu.cn
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#' alertmanager/*
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#' blackboxExporter/*
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#' kubeStateMetrics/*
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#' nodeExporter/*
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#' prometheus/*
sed -i 's#quay.io#quay.mirrors.ustc.edu.cn#' prometheusOperator/*
```
## 安装：
```bash
kubectl create -f setup
kubectl apply -f alertmanager
kubectl apply -f blackboxExporter
kubectl apply -f kubePrometheus
kubectl apply -f kubernetesControlPlane
kubectl apply -f kubeStateMetrics
kubectl apply -f nodeExporter
kubectl apply -f prometheus
kubectl apply -f prometheusAdapter
kubectl apply -f prometheusOperator
kubectl apply -f grafana
```

## ingress 参考
### 证书
```bash
kubectl -n monitoring create secret tls [名字] \
  --cert=[证书位置] \
  --key=[证书私钥位置]
```
### base auth
```bash
yum install httpd-tools -y
htpasswd -c auth 【用户名】

kubectl -n monitoring create secret generic basic-auth --from-file=auth
```

### ingress，prometheus和alertmanager使用了base auth
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus.example.com
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - admin"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - prometheus.example.com
      secretName: [证书名称]
  rules:
    - host: prometheus.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-k8s
                port:
                  name: web
```
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager.example.com
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required - admin"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - alertmanager.example.com
      secretName: [证书名称]
  rules:
    - host: alertmanager.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: alertmanager-main
                port:
                  name: web
```
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana.example.com
  namespace: monitoring
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - grafana.example.com
      secretName: [证书名称]
  rules:
    - host: grafana.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  name: http
```

## 解决kube-controller-manager 和 kube-scheduler一直报错的问题

```bash
vim /etc/kubernetes/manifests/kube-controller-manager.yaml
vim /etc/kubernetes/manifests/kube-scheduler.yaml

#将--bind-address=127.0.0.1 改为 --bind-address=0.0.0.0

kubectl apply -f kube-system-repair
```
