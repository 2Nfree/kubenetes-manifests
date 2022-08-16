# 如何使用
当前部署集群使用了helm charts

```bash
#创建namespace
kubectl create ns elastic

# 运行容器生成证书
docker run --name elastic-charts-certs -i -w /app elasticsearch:7.17.3 /bin/sh -c  \
  "elasticsearch-certutil ca --out /app/elastic-stack-ca.p12 --pass '' && \
    elasticsearch-certutil cert --name security-master --dns \
    security-master --ca /app/elastic-stack-ca.p12 --pass '' --ca-pass '' --out /app/elastic-certificates.p12"

# 从容器中将生成的证书拷贝出来
docker cp elastic-charts-certs:/app/elastic-certificates.p12 ./ 

# 删除容器
docker rm -f elastic-charts-certs

# 将 pcks12 中的信息分离出来，写入文件
openssl pkcs12 -nodes -passin pass:'' -in elastic-certificates.p12 -out elastic-certificate.pem

# 添加证书
kubectl create secret generic elastic-certificates --from-file=elastic-certificates.p12 -n elastic
kubectl create secret generic elastic-certificate-pem --from-file=elastic-certificate.pem -n elastic

# 设置集群用户名密码，用户名不建议修改
kubectl create secret generic elastic-credentials \
  --from-literal=username=elastic --from-literal=password=【密码】 -n elastic
```
安装
```bash
#版本为helm3
helm repo add elastic https://helm.elastic.co

#安装 ElasticSearch Master 节点
helm install elasticsearch-master -f es-master.yaml --version 7.17.3 --namespace elastic elastic/elasticsearch

#安装 ElasticSearch Data 节点
helm install elasticsearch-data -f es-data.yaml --version 7.17.3 --namespace elastic elastic/elasticsearch

#安装 ElasticSearch Client 节点
helm install elasticsearch-client -f es-client.yaml --version 7.17.3 --namespace elastic elastic/elasticsearch 

#安装kibana
helm install kibana -f kibana.yaml --version 7.17.3 --namespace elastic elastic/kibana

#卸载
helm delete elasticsearch-master -n elastic
helm delete elasticsearch-data -n elastic
helm delete elasticsearch-client -n elastic
helm delete kibana -n elastic

#删除卷
kubectl delete pvc [pvc name] -n elastic
```

配置pod日志收集

```bash
#安装fluentd收集pod日志
kubectl apply -f es-fluentd-configmap.yaml
kubectl apply -f es-fluentd-daemonset.yaml

#设置需要收集日志的node节点
kubectl label nodes [node名字] beta.kubernetes.io/fluentd-ds-ready=true

#将需要收集日志的pod打上标签
kubectl label pod [pod名字] logging=true -n [所在命名空间]

#删除标签
kubectl label pod [pod名字] logging- -n [所在命名空间]

#或者在yaml文件中设置label
```