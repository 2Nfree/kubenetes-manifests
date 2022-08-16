# 如何使用

- nacos-mysql: nacos数据库
- nacos-cluster：3节点集群模式
- nacos-standalone: 单节点模式

## PS:注意配置中的存储类

## 启动集群模式
```bash
kubectl apply -f nacos-mysql-statefulset.yaml
kubectl apply -f nacos-cluster-statefulset.yaml
kubectl apply -f nacos-service.yaml
```

## 启动单节点模式
```bash
kubectl apply -f nacos-mysql-statefulset.yaml
kubectl apply -f nacos-standalone-statefulset.yaml
kubectl apply -f nacos-service.yaml
```

ingress配置参考nacos-ingress.yaml