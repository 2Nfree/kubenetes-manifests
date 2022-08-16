# 如何使用

## 注意配置文件中的存储类设置，以及postgres数据库密码

### sonar-postgresql.yaml
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-sonar
  namespace: cicd
spec:
  selector:
    matchLabels:
      app: postgres-sonar
  serviceName: "postgres-sonar"
  replicas: 1
  template:
    metadata:
      labels:
        app: postgres-sonar
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: postgres-sonar
        image: postgres:alpine
        ports:
        - containerPort: 5432
        volumeMounts:
          - name: postgre-storage
            mountPath: /var/lib/postgresql/data
        env:
        - name: POSTGRES_DB
          value: "sonarDB"
        - name: POSTGRES_USER
          value: "sonarUser"
        - name: POSTGRES_PASSWORD 
          #修改数据库密码
          value: "数据库密码"
  volumeClaimTemplates:
  - metadata:
      name: postgre-storage
    spec:
      accessModes: [ "ReadWriteMany" ]
      #换成自己的存储类
      storageClassName: "gluster"
      resources:
        requests:
          storage: 50Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-sonar
  namespace: cicd
  labels:
    app: postgres-sonar
spec:
  ports:
  - name: sonarqube
    port: 5432
    targetPort: 5432
    protocol: TCP
  selector:
    app: postgres-sonar
```

### sonar-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name:  sonar-deployment
  namespace: cicd
  labels:
    app:  sonar-deployment
spec:
  selector:
    matchLabels:
      app: sonar-deployment
  replicas: 1
  template:
    metadata:
      labels:
        app:  sonar-deployment
    spec:
      initContainers:
      - name: init-max-map-count
        image: busybox
        imagePullPolicy: IfNotPresent
        command: ["sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
      - name: init-file-max
        image: busybox
        imagePullPolicy: IfNotPresent
        command: ["sysctl", "-w", "fs.file-max=65536"]
        securityContext:
          privileged: true
      containers:
      - name:  sonar-deployment
        image:  sonarqube:lts
        resources:
          requests:
            cpu: 2000m
            memory: 2048Mi
          limits:
            cpu: 2000m
            memory: 2048Mi
        env:
        - name: SONARQUBE_JDBC_USERNAME
          value: "sonarUser"
        - name: SONARQUBE_JDBC_PASSWORD
          #注意密码
          value: "数据库密码"
        - name: SONARQUBE_JDBC_URL
          value: "jdbc:postgresql://postgres-sonar.cicd:5432/sonarDB"
        ports:
        - containerPort: 9000
        volumeMounts:
        - mountPath: /etc/localtime
          name: localtime
        - mountPath: /opt/sonarqube/conf
          name: sonar-storage
          subPath: conf
        - mountPath: /opt/sonarqube/data
          name: sonar-storage
          subPath: data
        - mountPath: /opt/sonarqube/extensions
          name: sonar-storage
          subPath: extensions
      volumes:
        - name: localtime
          hostPath:
            #时区为上海，有其他需要自行修改
            path: /usr/share/zoneinfo/Asia/Shanghai
        - name: sonar-storage
          persistentVolumeClaim:
            claimName: sonar-storage
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: sonarqube
  namespace: cicd
  labels:
    app: sonarqube
spec:
  ports:
  - name: sonarqube
    port: 9000
    targetPort: 9000
    protocol: TCP
  selector:
    app: sonar-deployment
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonar-storage
  namespace: cicd
  labels:
    app: sonar-storage
spec:
  #换成自己的存储类
  storageClassName: gluster
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 30Gi
```

```bash
kubectl apply -f sonar-postgresql.yaml
kubectl apply -f sonar-deployment.yaml
```

### ingress配置参考sonar-ingress.yaml