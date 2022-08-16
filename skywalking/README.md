# 如何使用
```bash
#安装OAP和UI
kubectl create ns skywalking
helm install skywalking -f skywalking-charts.yaml --namespace skywalking skywalking/skywalking

#安装CertManager
wget https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
kubectl apply -f cert-manager.crds.yaml
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.9.1

#安装skywalking-swck
kubectl apply -f operator-bundle.yaml

#安装自定义指标适配器
kubectl apply -f adapter-bundle.yaml
```


## ingress示例

skywalking-ingress.yaml