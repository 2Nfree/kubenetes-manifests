# 如何使用

记得修改yaml中的参数

部分参数说明：
- enabled_plugins：声明开启的插件名
- default_pass/default_pass：声明用户名和密码（虽然有部分文章记录可以通过环境变量的方式声明，但是经测试，针对此版本如果指定了configmap即rabbitmq的配置文件，声明的环境变量是没有用的，都需要在配置文件中指定）
- cluster_formation.k8s.address_type：从k8s返回的Pod容器列表中计算对等节点列表，这里只能使用主机名，官方示例中是ip，但是默认情况下在k8s中pod的ip都是不固定的，因此可能导致节点的配置和数据丢失，后面的yaml中会通过引用元数据的方式固定pod的主机名。

```bash
kubectl apply -f RabbitMq-ConfigMap.yaml
kubectl apply -f RabbitMq-ServerAccount.yaml
kubectl apply -f RabbitMq-StatefulSet.yaml
kubectl apply -f RabbitMq-Service.yaml
```