# 如何使用

## rook存储方式

rook默认使用所有节点的所有资源

rook operator自动在所有节点上启动OSD设备

Rook会用如下标准监控并发现可用设备：
- 设备没有分区
- 设备没有格式化的文件系统
- Rook不会使用不满足以上标准的设备。另外也可以通过修改配置文件，指定哪些节点或者设备会被使用

当前添加磁盘为```/dev/vdb```
```bash
#查看磁盘情况
lsblk -f

#为以防万一，初始化磁盘
yum install gdisk -y
sgdisk --zap-all /dev/vdb
dd if=/dev/zero of="/dev/vdb" bs=1M count=100 oflag=direct,dsync
blkdiscard /dev/vdb
partprobe /dev/vdb
```
## 初始化环境
```bash
#确认安装lvm2
yum install lvm2 -y
#启用rbd模块
modprobe rbd
cat > /etc/rc.sysinit << EOF
#!/bin/bash
for file in /etc/sysconfig/modules/*.modules
do
  [ -x \$file ] && \$file
done
EOF
cat > /etc/sysconfig/modules/rbd.modules << EOF
modprobe rbd
EOF
chmod 755 /etc/sysconfig/modules/rbd.modules
lsmod |grep rbd
```

## 部署Rook Operator
```bash
#这个文件是K8S的编排文件直接便可以使用K8S命令将文件之中编排的资源全部安装到集群之中
#需要注意的只有一点，如果你想讲rook和对应的ceph容器全部安装到一个特定的项目之中去，那么建议优先创建项目和命名空间，并修改配置文件中的namespace
#默认common文件资源会自动创建一个叫做rook-ceph的命名空间，后续所有的资源与容器都会安装到这里面去。
kubectl create -f crds.yaml
kubectl create -f common.yaml

#操作器是整个ROOK的核心，后续的集群创建、自动编排、拓展等等功能全部是在操作器的基础之上实现的
#操作器具备主机权限能够监控服务所依赖的容器运行情况和主机的硬盘变更情况，相当于大脑
#安装完成之后需要等待所有的操作器正常运行之后才能继续还是ceph分布式集群的安装
#可以修改operator.yaml中的配置，开启磁盘自动发现
#默认不开启自动发现，开启自动发现后，当你接入新的裸磁盘设备时会自动创建osd，但是将磁盘取消挂载不会删除osd
#ROOK_ENABLE_DISCOVERY_DAEMON: true

kubectl create -f operator.yaml

#查看安装状态，等待所有的pod都是running状态之后继续下一步
kubectl -n rook-ceph get pod
```

## 部署rook-ceph集群
```bash
#通过一个yaml编排文件能够对整个Ceph组件部署、硬盘配置、集群配置等一系列操作
kubectl apply -f cluster.yaml

#其中osd-0、osd-1、osd-2容器必须是存在且正常的，如果上述pod均正常运行成功，则视为集群安装成功。
kubectl -n rook-ceph get pod
```
*PS：国内无法下载镜像需要自己pull，可以上传的个人的镜像仓库，参考operator-cn.yaml、cluster-cn.yaml*
```bash
cat operator.yaml | grep image
cat operator.yaml | grep IMAGE
```

## 查看ceph集群状态
```bash
#安装工具
kubectl apply -f toolbox.yaml

#进入管理pod
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash

#查看状态
ceph status
ceph osd status
ceph df 
rados df
```

## 存储类
集群搭建完毕之后便是存储的创建

目前Ceph支持块存储、文件系统存储、对象存储三种方案，K8S官方对接的存储方案是块存储，他也是比较稳定的方案，但是块存储目前不支持多主机读写（只能RWO）；

文件系统存储是支持多主机存储的性能也不错；对象存储系统IO性能太差建议不考虑，除非特殊需求，可以根据要求自行决定。

存储系统创建完成之后对这个系统添加一个存储类之后整个集群才能通过K8S的存储类直接使用Ceph存储。

*PS：涉及到格式化类型建议使用XFS而不是EXT4，因为EXT4格式化后会生成一个lost+found文件夹，某些容器要求挂载的数据盘必须是空的，例如Mysql*

下面用共享文件系统作为示例，如果使用块存储参考storageclass-block

### CephFS存储类（共享文件系统）

```bash
#创建文件系统池
#当前文件为测试用，生产环境建议修改分片数为2或3
kubectl apply -f ceph-filesystem.yaml

#查看文件系统pod创建情况
kubectl -n rook-ceph get pod -l app=rook-ceph-mds

#进入管理pod查看状态
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
ceph status

#创建文件系统存储类
kubectl apply -f storageclass-cephfs.yaml

#查看存储类
kubectl get sc

#设置默认存储
kubectl patch sc rook-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

#创建测试用的pvc
kubectl apply -f pvc-cephfs-test.yaml

#如果pvc状态为Brond则成功
kubectl get pvc -A
kubectl delete -f pvc-cephfs-test.yaml
```

## 开启dashboard

当前使用的是ingress的方式部署
```bash
#创建证书
sh ceph-tls.sh

#部署
kubectl apply -f dashboard-ingress-https.yaml

#获取默认密码
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}"|base64 --decode && echo
```