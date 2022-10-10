# 集群配置
```bash
#获取集群pod的IP
kubectl get pod -n redis -o wide

#进入redis pod
kubectl exec -it -n redis redis-0 -- bash

#使用查询的ip初始化集群
#-a 密码
redis-cli -a 密码 --cluster create \
10.244.61.30:6379 \
10.244.158.249:6379 \
10.244.146.217:6379 \
10.244.61.31:6379 \
10.244.158.250:6379 \
10.244.146.225:6379 \
--cluster-replicas 1

#连接redis查看集群状态
cluster info
cluster nodes
```

## PS:注意配置文件中的密码，需要手动更改