# day11-kubernetes

## PART1. kubernetes资源限制

### 1.1 kubernetes中资源限制概括

![K8S资源限制概括](./img/K8S资源限制概括.png)

![pod运行情况](./img/pod运行情况.png)

1000毫核 = 1核

加资源限制时,不能超过物理机的毫核数.

![K8S资源限制示意图](./img/K8S资源限制示意图.png)

一般做资源限制时,只限制CPU和内存,不限制网卡和磁盘,因为网卡和磁盘很难衡量.

- CPU:以核心为单位(毫核)
- 内存:以字节为单位

- requests:是kubernetes scheduler执行pod调度时,node节点至少拥有的资源数量.也就是说node节点至少拥有requests定义的资源,才能参与调度.
- limits:是pod运行成功后,最多可以使用的资源上限

通常requests <= limits.可以认为limits是硬限制,requests是软限制.

### 1.2 kubernetes对单个容器的CPU及memory实现资源限制

#### 1.2.1 对memory实现资源限制

- step1. 制作并推送镜像

```
root@ks8-harbor-2:~# docker pull lorel/docker-stress-ng
Using default tag: latest
latest: Pulling from lorel/docker-stress-ng
Image docker.io/lorel/docker-stress-ng:latest uses outdated schema1 manifest format. Please upgrade to a schema2 image for better future compatibility. More information at https://docs.docker.com/registry/spec/deprecated-schema-v1/
c52e3ed763ff: Pull complete 
a3ed95caeb02: Pull complete 
7f831269c70e: Pull complete 
Digest: sha256:c8776b750869e274b340f8e8eb9a7d8fb2472edd5b25ff5b7d55728bca681322
Status: Downloaded newer image for lorel/docker-stress-ng:latest
docker.io/lorel/docker-stress-ng:latest
root@ks8-harbor-2:~# docker tag lorel/docker-stress-ng:latest harbor.k8s.com/limit-case/docker-stress-ng:v1
root@ks8-harbor-2:~# docker push harbor.k8s.com/limit-case/docker-stress-ng:v1
The push refers to repository [harbor.k8s.com/limit-case/docker-stress-ng]
5f70bf18a086: Pushed 
ea580b0285fe: Pushed 
6102f0d2ad33: Pushed 
v1: digest: sha256:5768a5d8e196be8c8fabbda04d937aabe1407f397b2f12e1fea2573e4b9d9bef size: 1563
```

- step2. 创建pod

```
root@k8s-master-1:~# cd k8s-data/
root@k8s-master-1:~/k8s-data# ls
dubbo-yaml  gray-released-yaml  hpa  ingress  jenkins-yaml  mysql-yaml  nginx-webapp-yaml  redis-yaml  tomcat-app-log-yaml  tomcat-webapp-yaml  wordpress-yaml  zookeeper-yaml
root@k8s-master-1:~/k8s-data# mkdir limit-case
root@k8s-master-1:~/k8s-data# cd limit-case/
root@k8s-master-1:~/k8s-data/limit-case# vim case1-pod-memory-limit.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case1-pod-memory-limit.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: limit-test-deployment
  namespace: erp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: limit-test-pod
  template:
    metadata:
      labels:
        app: limit-test-pod
    spec:
      containers:
      - name: limit-test-container
        image: harbor.k8s.com/limit-case/docker-stress-ng:v1
        resources:
          limits:
            memory: "512Mi"
          requests:
            memory: "100Mi"
        # 此处的参数定义了只能使用2个CPU内核 且该容器最多使用512M的内存 2表示2个线程 256M表示每个线程最多占用的内存
        args: ["--vm", "2", "--vm-bytes", "256M"]
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case1-pod-memory-limit.yaml 
deployment.apps/limit-test-deployment created
root@k8s-master-1:~/k8s-data/limit-case# kubectl get pod -n erp|grep limit-test-deployment
limit-test-deployment-859f879667-lkv6g             1/1     Running   0          12s
```

- step3. 查看Pod运行时的指标数据

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl top pod limit-test-deployment-859f879667-lkv6g -n erp
W0604 10:32:56.602789    5192 top_pod.go:140] Using json format to get metrics. Next release will switch to protocol-buffers, switch early by passing --use-protocol-buffers flag
NAME                                     CPU(cores)   MEMORY(bytes)   
limit-test-deployment-859f879667-lkv6g   1891m        510Mi 
```

可以看到,内存最大使用量不会超过512MB

- step4. 删除pod

这个太占资源了,演示完了记得删

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case1-pod-memory-limit.yaml 
deployment.apps "limit-test-deployment" deleted
```

推荐限制:

|容器|限制CPU|限制内存|
|:-:|:-:|:-:|
|nginx|2C|2G|
|微服务|2C|2G-3G|
|DB(如MySQL/ES)|4C|6G-8G|

#### 1.2.2 对cpu和memory实现资源限制

- step1. 创建pod

```
root@k8s-master-1:~/k8s-data/limit-case# vim case2-pod-memory-and-cpu-limit.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case2-pod-memory-and-cpu-limit.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: limit-test-deployment
  namespace: erp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: limit-test-pod
  template:
    metadata:
      labels:
        app: limit-test-pod
    spec:
      containers:
      - name: limit-test-container
        image: harbor.k8s.com/limit-case/docker-stress-ng:v1
        resources:
          limits:
            memory: "512Mi"
            cpu: "1.2"
          requests:
            memory: "100Mi"
            cpu: "200m"
        args: ["--vm", "2", "--vm-bytes", "256M"]
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get pod -n erp | grep  limit-test-deployment
limit-test-deployment-948d64f95-zv7mr              1/1     Running   0          18s
```

- step2. 查看Pod运行时的指标数据

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl top pod limit-test-deployment-948d64f95-zv7mr -n erp
W0604 10:46:04.196629   17959 top_pod.go:140] Using json format to get metrics. Next release will switch to protocol-buffers, switch early by passing --use-protocol-buffers flag
NAME                                    CPU(cores)   MEMORY(bytes)   
limit-test-deployment-948d64f95-zv7mr   1201m        429Mi 
```

- step3. 删除pod

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case2-pod-memory-and-cpu-limit.yaml 
deployment.apps "limit-test-deployment" deleted
```

### 1.3 kubernetes对单个pod的CPU及memory实现资源限制

#### 1.3.1 LimitRange

[LimitRange](https://kubernetes.io/zh/docs/concepts/policy/limit-range/)是对具体某个Pod或容器的资源使用进行限制.在一定程度上可以避免运维人员对某个Pod或容器的资源限制评估不太准确的情况发生.LimitRange是在命名空间内限制资源分配(给多个Pod或Container)的策略对象.

Limit Range的作用:

- 限制namespace中每个Pod或容器的最小与最大计算资源
- 限制namespace中每个Pod或容器计算资源request、limit之间的比例
- 限制namespace中每个存储卷声明(PersistentVolumeClaim)可使用的最小与最大存储空间
- 设置namespace中容器默认计算资源的request、limit,并在运行时自动注入到容器中

注意:

- LimitRange的验证仅在Pod准入阶段进行,不对正在运行的Pod进行验证
- 在命名空间的总限制值小于Pod或Container的限制值的总和的情况下,可能会产生资源竞争.在这种情况下,将不会创建Container或Pod.
- 竞争和对LimitRange的改变都不会影响任何已经创建了的资源

```
root@k8s-master-1:~/k8s-data/limit-case# vim case3-LimitRange.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case3-LimitRange.yaml
```

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range-erp
  namespace: erp
spec:
  limits:
    # 限制的资源类型为容器
    - type: Container
      # 限制容器的资源上限
      max:
        # 限制单个容器的最大CPU
        cpu: "2"
        # 限制单个容器的最大内存
        memory: "2Gi"
      # 限制资源下限
      min:
        # 限制单个容器的最小CPU
        cpu: "500m"
        # 限制单个容器的最小内存
        memory: "512Mi"
      # 默认单个容器的资源
      default:
        # 默认单个容器的CPU
        cpu: "500m"
        # 默认单个容器的内存
        memory: "512Mi"
      # 默认单个容器能够参与调度的节点资源要求
      defaultRequest:
        # 单个容器对参与调度的节点的CPU要求
        cpu: "500m"
        # 单个容器对参与调度的节点的内存要求
        memory: "512Mi"
      # 限制limit/requests的最大比值
      # 为了避免能够参与调度的节点资源不足以运行容器
      # 所以通常这个比值设置的不会太高
      maxLimitRequestRatio:
        # 限制CPU的 limit/requests的最大比值
        cpu: 2
        # 限制内存的 limit/requests的最大比值
        memory: 2
    # 限制的资源类型为Pod
    - type: Pod
      # 限制Pod的资源上限
      max:
        # 限制单个Pod的最大CPU
        cpu: "4"
        # 限制单个Pod的最大内存
        memory: "4Gi"
    # 限制的资源类型为PVC
    - type: PersistentVolumeClaim
      # 限制PVC的资源上限
      max:
        # 限制PVC的可申请存储空间上限
        storage: 50Gi
      # 限制PVC的资源下限
      min:
        # 限制PVC的可申请存储空间下限
        storage: 1Gi
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case3-LimitRange.yaml 
limitrange/limit-range-erp created
root@k8s-master-1:~/k8s-data/limit-case# kubectl get limitranges -n erp
NAME              CREATED AT
limit-range-erp   2022-06-07T00:39:39Z
root@k8s-master-1:~/k8s-data/limit-case# kubectl describe limitranges limit-range-erp -n erp
Name:                  limit-range-erp
Namespace:             erp
Type                   Resource  Min    Max   Default Request  Default Limit  Max Limit/Request Ratio
----                   --------  ---    ---   ---------------  -------------  -----------------------
Container              cpu       500m   2     500m             500m           2
Container              memory    512Mi  2Gi   512Mi            512Mi          2
Pod                    cpu       -      4     -                -              -
Pod                    memory    -      4Gi   -                -              -
PersistentVolumeClaim  storage   1Gi    50Gi  -                -              -
```

#### 1.3.2 限制案例1:CPU与内存的RequestRatio比例限制

- step1. 创建符合LimitRange要求的Pod

```
root@k8s-master-1:~/k8s-data/limit-case# vim case4-pod-requestRatio-limit.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case4-pod-requestRatio-limit.yaml
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-wordpress-deployment-label
  name: erp-wordpress-deployment
  namespace: erp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: erp-wordpress-selector
  template:
    metadata:
      labels:
        app: erp-wordpress-selector
    spec:
      containers:
      - name: erp-wordpress-nginx-container
        image: harbor.k8s.com/erp/nginx:1.16.1
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi

      - name: erp-wordpress-php-container
        image: harbor.k8s.com/pub-images/php:5.6-fpm-alpine
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case4-pod-requestRatio-limit.yaml 
deployment.apps/erp-wordpress-deployment created
root@k8s-master-1:~/k8s-data/limit-case# kubectl get pod -n erp|grep erp-wordpress-deployment
erp-wordpress-deployment-7d9bbdfd79-gr2dh          2/2     Running   0          34s
```

- step2. 删除符合要求的Pod

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case4-pod-requestRatio-limit.yaml 
deployment.apps "erp-wordpress-deployment" deleted
```

- step3. 修改yaml文件,使得Pod不符合LimitRange的资源限制要求

```
root@k8s-master-1:~/k8s-data/limit-case# vim case4-pod-requestRatio-limit.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case4-pod-requestRatio-limit.yaml
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-wordpress-deployment-label
  name: erp-wordpress-deployment
  namespace: erp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: erp-wordpress-selector
  template:
    metadata:
      labels:
        app: erp-wordpress-selector
    spec:
      containers:
      - name: erp-wordpress-nginx-container
        image: harbor.k8s.com/erp/nginx:1.16.1
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 2
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi

      - name: erp-wordpress-php-container
        image: harbor.k8s.com/pub-images/php:5.6-fpm-alpine
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
```

注意容器`erp-wordpress-nginx-container`,`limits.cpu`:`requests.cpu` = 4:1,超过了LimitRange的`maxLimitRequestRatio.cpu`的值(`maxLimitRequestRatio.cpu` = 2)

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case4-pod-requestRatio-limit.yaml 
deployment.apps/erp-wordpress-deployment created
```

- step4. 查看错误信息

此时提示创建deployment是成功的,没有报错信息,但查看pod信息可以发现并不存在该pod:

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get pod -n erp|grep erp-wordpress-deployment
root@k8s-master-1:~/k8s-data/limit-case# 
```

查看报错信息:

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get pod -n erp|grep erp-wordpress-deployment
root@k8s-master-1:~/k8s-data/limit-case# kubectl get deployments erp-wordpress-deployment -n erp -o json
```

```json
{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "annotations": {
            "deployment.kubernetes.io/revision": "1",
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"erp-wordpress-deployment-label\"},\"name\":\"erp-wordpress-deployment\",\"namespace\":\"erp\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"erp-wordpress-selector\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"erp-wordpress-selector\"}},\"spec\":{\"containers\":[{\"image\":\"harbor.k8s.com/erp/nginx:1.16.1\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-wordpress-nginx-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":2,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"}}},{\"image\":\"harbor.k8s.com/pub-images/php:5.6-fpm-alpine\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-wordpress-php-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":1,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"}}}]}}}}\n"
        },
        "creationTimestamp": "2022-06-07T01:23:10Z",
        "generation": 1,
        "labels": {
            "app": "erp-wordpress-deployment-label"
        },
        "name": "erp-wordpress-deployment",
        "namespace": "erp",
        "resourceVersion": "1731999",
        "uid": "c4be58e7-4265-46f3-85ff-81af82e3b4b5"
    },
    "spec": {
        "progressDeadlineSeconds": 600,
        "replicas": 1,
        "revisionHistoryLimit": 10,
        "selector": {
            "matchLabels": {
                "app": "erp-wordpress-selector"
            }
        },
        "strategy": {
            "rollingUpdate": {
                "maxSurge": "25%",
                "maxUnavailable": "25%"
            },
            "type": "RollingUpdate"
        },
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "erp-wordpress-selector"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": "harbor.k8s.com/erp/nginx:1.16.1",
                        "imagePullPolicy": "Always",
                        "name": "erp-wordpress-nginx-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "2",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "500m",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    },
                    {
                        "image": "harbor.k8s.com/pub-images/php:5.6-fpm-alpine",
                        "imagePullPolicy": "Always",
                        "name": "erp-wordpress-php-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "1",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "500m",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    }
                ],
                "dnsPolicy": "ClusterFirst",
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "terminationGracePeriodSeconds": 30
            }
        }
    },
    "status": {
        "conditions": [
            {
                "lastTransitionTime": "2022-06-07T01:23:10Z",
                "lastUpdateTime": "2022-06-07T01:23:10Z",
                "message": "Created new replica set \"erp-wordpress-deployment-766d487b7\"",
                "reason": "NewReplicaSetCreated",
                "status": "True",
                "type": "Progressing"
            },
            {
                "lastTransitionTime": "2022-06-07T01:23:10Z",
                "lastUpdateTime": "2022-06-07T01:23:10Z",
                "message": "Deployment does not have minimum availability.",
                "reason": "MinimumReplicasUnavailable",
                "status": "False",
                "type": "Available"
            },
            {
                "lastTransitionTime": "2022-06-07T01:23:10Z",
                "lastUpdateTime": "2022-06-07T01:23:10Z",
                "message": "pods \"erp-wordpress-deployment-766d487b7-dqt9p\" is forbidden: cpu max limit to request ratio per Container is 2, but provided ratio is 4.000000",
                "reason": "FailedCreate",
                "status": "True",
                "type": "ReplicaFailure"
            }
        ],
        "observedGeneration": 1,
        "unavailableReplicas": 1
    }
}
```

- 注:`status.contidions.message`中,有错误信息:`"pods \"erp-wordpress-deployment-766d487b7-dqt9p\" is forbidden: cpu max limit to request ratio per Container is 2, but provided ratio is 4.000000"`
- 注:不加`-o json`选项,是看不到这个报错信息的.且使用`kubectl describe deployment`也是看不到的.
- 注:使用`-o yaml`选项也可以看到这个报错信息

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get deployments erp-wordpress-deployment -n erp -o yaml
apiVersion: apps/v1
```

```yaml
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"erp-wordpress-deployment-label"},"name":"erp-wordpress-deployment","namespace":"erp"},"spec":{"replicas":1,"selector":{"matchLabels":{"app":"erp-wordpress-selector"}},"template":{"metadata":{"labels":{"app":"erp-wordpress-selector"}},"spec":{"containers":[{"image":"harbor.k8s.com/erp/nginx:1.16.1","imagePullPolicy":"Always","name":"erp-wordpress-nginx-container","ports":[{"containerPort":80,"name":"http","protocol":"TCP"}],"resources":{"limits":{"cpu":2,"memory":"1Gi"},"requests":{"cpu":"500m","memory":"512Mi"}}},{"image":"harbor.k8s.com/pub-images/php:5.6-fpm-alpine","imagePullPolicy":"Always","name":"erp-wordpress-php-container","ports":[{"containerPort":80,"name":"http","protocol":"TCP"}],"resources":{"limits":{"cpu":1,"memory":"1Gi"},"requests":{"cpu":"500m","memory":"512Mi"}}}]}}}}
  creationTimestamp: "2022-06-07T01:23:10Z"
  generation: 1
  labels:
    app: erp-wordpress-deployment-label
  name: erp-wordpress-deployment
  namespace: erp
  resourceVersion: "1733286"
  uid: c4be58e7-4265-46f3-85ff-81af82e3b4b5
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: erp-wordpress-selector
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: erp-wordpress-selector
    spec:
      containers:
      - image: harbor.k8s.com/erp/nginx:1.16.1
        imagePullPolicy: Always
        name: erp-wordpress-nginx-container
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        resources:
          limits:
            cpu: "2"
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      - image: harbor.k8s.com/pub-images/php:5.6-fpm-alpine
        imagePullPolicy: Always
        name: erp-wordpress-php-container
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        resources:
          limits:
            cpu: "1"
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  conditions:
  - lastTransitionTime: "2022-06-07T01:23:10Z"
    lastUpdateTime: "2022-06-07T01:23:10Z"
    message: Deployment does not have minimum availability.
    reason: MinimumReplicasUnavailable
    status: "False"
    type: Available
  - lastTransitionTime: "2022-06-07T01:23:10Z"
    lastUpdateTime: "2022-06-07T01:23:10Z"
    message: 'pods "erp-wordpress-deployment-766d487b7-dqt9p" is forbidden: cpu max
      limit to request ratio per Container is 2, but provided ratio is 4.000000'
    reason: FailedCreate
    status: "True"
    type: ReplicaFailure
  - lastTransitionTime: "2022-06-07T01:33:11Z"
    lastUpdateTime: "2022-06-07T01:33:11Z"
    message: ReplicaSet "erp-wordpress-deployment-766d487b7" has timed out progressing.
    reason: ProgressDeadlineExceeded
    status: "False"
    type: Progressing
  observedGeneration: 1
  unavailableReplicas: 1
```

- step5. 删除deployment

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case4-pod-requestRatio-limit.yaml 
deployment.apps "erp-wordpress-deployment" deleted
```

#### 1.3.3 CPU与内存或超分限制

##### a. CPU超分限制

- step1. 编写yaml文件

```
root@k8s-master-1:~/k8s-data/limit-case# vim case5-pod-cpu-limit.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case5-pod-cpu-limit.yaml
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-wordpress-deployment-label
  name: erp-wordpress-deployment
  namespace: erp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: erp-wordpress-selector
  template:
    metadata:
      labels:
        app: erp-wordpress-selector
    spec:
      containers:
      - name: erp-wordpress-nginx-container
        image: harbor.k8s.com/erp/nginx:1.16.1
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 4
            memory: 1Gi
          requests:
            cpu: 2
            memory: 512Mi

      - name: erp-wordpress-php-container
        image: harbor.k8s.com/pub-images/php:5.6-fpm-alpine
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case5-pod-cpu-limit.yaml 
deployment.apps/erp-wordpress-deployment created
```

- step2. 查看报错信息

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get deployments erp-wordpress-deployment -n erp -o json
```

```json
{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "annotations": {
            "deployment.kubernetes.io/revision": "1",
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"erp-wordpress-deployment-label\"},\"name\":\"erp-wordpress-deployment\",\"namespace\":\"erp\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"erp-wordpress-selector\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"erp-wordpress-selector\"}},\"spec\":{\"containers\":[{\"image\":\"harbor.k8s.com/erp/nginx:1.16.1\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-wordpress-nginx-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":4,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":2,\"memory\":\"512Mi\"}}},{\"image\":\"harbor.k8s.com/pub-images/php:5.6-fpm-alpine\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-wordpress-php-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":1,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"}}}]}}}}\n"
        },
        "creationTimestamp": "2022-06-07T01:38:55Z",
        "generation": 1,
        "labels": {
            "app": "erp-wordpress-deployment-label"
        },
        "name": "erp-wordpress-deployment",
        "namespace": "erp",
        "resourceVersion": "1734029",
        "uid": "ab8ee6d7-a790-41a8-955e-f90cc3e05a00"
    },
    "spec": {
        "progressDeadlineSeconds": 600,
        "replicas": 1,
        "revisionHistoryLimit": 10,
        "selector": {
            "matchLabels": {
                "app": "erp-wordpress-selector"
            }
        },
        "strategy": {
            "rollingUpdate": {
                "maxSurge": "25%",
                "maxUnavailable": "25%"
            },
            "type": "RollingUpdate"
        },
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "erp-wordpress-selector"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": "harbor.k8s.com/erp/nginx:1.16.1",
                        "imagePullPolicy": "Always",
                        "name": "erp-wordpress-nginx-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "4",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "2",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    },
                    {
                        "image": "harbor.k8s.com/pub-images/php:5.6-fpm-alpine",
                        "imagePullPolicy": "Always",
                        "name": "erp-wordpress-php-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "1",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "500m",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    }
                ],
                "dnsPolicy": "ClusterFirst",
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "terminationGracePeriodSeconds": 30
            }
        }
    },
    "status": {
        "conditions": [
            {
                "lastTransitionTime": "2022-06-07T01:38:55Z",
                "lastUpdateTime": "2022-06-07T01:38:55Z",
                "message": "Created new replica set \"erp-wordpress-deployment-866bdbd86d\"",
                "reason": "NewReplicaSetCreated",
                "status": "True",
                "type": "Progressing"
            },
            {
                "lastTransitionTime": "2022-06-07T01:38:55Z",
                "lastUpdateTime": "2022-06-07T01:38:55Z",
                "message": "Deployment does not have minimum availability.",
                "reason": "MinimumReplicasUnavailable",
                "status": "False",
                "type": "Available"
            },
            {
                "lastTransitionTime": "2022-06-07T01:38:55Z",
                "lastUpdateTime": "2022-06-07T01:38:55Z",
                "message": "pods \"erp-wordpress-deployment-866bdbd86d-vrgnm\" is forbidden: [maximum cpu usage per Container is 2, but limit is 4, maximum cpu usage per Pod is 4, but limit is 5]",
                "reason": "FailedCreate",
                "status": "True",
                "type": "ReplicaFailure"
            }
        ],
        "observedGeneration": 1,
        "unavailableReplicas": 1
    }
}
```

- step3. 删除deployment

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case5-pod-cpu-limit.yaml 
deployment.apps "erp-wordpress-deployment" deleted
```

##### b. 内存超分限制

- step1. 修改yaml文件

```
root@k8s-master-1:~/k8s-data/limit-case# vim case5-pod-cpu-limit.yaml 
root@k8s-master-1:~/k8s-data/limit-case# cat case5-pod-cpu-limit.yaml
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-wordpress-deployment-label
  name: erp-wordpress-deployment
  namespace: erp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: erp-wordpress-selector
  template:
    metadata:
      labels:
        app: erp-wordpress-selector
    spec:
      containers:
      - name: erp-wordpress-nginx-container
        image: harbor.k8s.com/erp/nginx:1.16.1
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 2
            memory: 8Gi
          requests:
            cpu: 1
            memory: 4Gi

      - name: erp-wordpress-php-container
        image: harbor.k8s.com/pub-images/php:5.6-fpm-alpine
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case5-pod-cpu-limit.yaml 
deployment.apps/erp-wordpress-deployment created
```

- step2. 查看报错信息

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get deployments erp-wordpress-deployment -n erp -o json
```

```json
{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "annotations": {
            "deployment.kubernetes.io/revision": "1",
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"erp-wordpress-deployment-label\"},\"name\":\"erp-wordpress-deployment\",\"namespace\":\"erp\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"erp-wordpress-selector\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"erp-wordpress-selector\"}},\"spec\":{\"containers\":[{\"image\":\"harbor.k8s.com/erp/nginx:1.16.1\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-wordpress-nginx-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":2,\"memory\":\"8Gi\"},\"requests\":{\"cpu\":1,\"memory\":\"4Gi\"}}},{\"image\":\"harbor.k8s.com/pub-images/php:5.6-fpm-alpine\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-wordpress-php-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":1,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"}}}]}}}}\n"
        },
        "creationTimestamp": "2022-06-07T01:43:49Z",
        "generation": 1,
        "labels": {
            "app": "erp-wordpress-deployment-label"
        },
        "name": "erp-wordpress-deployment",
        "namespace": "erp",
        "resourceVersion": "1734673",
        "uid": "6585187d-215f-4d1c-88e4-3fc69a7160eb"
    },
    "spec": {
        "progressDeadlineSeconds": 600,
        "replicas": 1,
        "revisionHistoryLimit": 10,
        "selector": {
            "matchLabels": {
                "app": "erp-wordpress-selector"
            }
        },
        "strategy": {
            "rollingUpdate": {
                "maxSurge": "25%",
                "maxUnavailable": "25%"
            },
            "type": "RollingUpdate"
        },
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "erp-wordpress-selector"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": "harbor.k8s.com/erp/nginx:1.16.1",
                        "imagePullPolicy": "Always",
                        "name": "erp-wordpress-nginx-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "2",
                                "memory": "8Gi"
                            },
                            "requests": {
                                "cpu": "1",
                                "memory": "4Gi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    },
                    {
                        "image": "harbor.k8s.com/pub-images/php:5.6-fpm-alpine",
                        "imagePullPolicy": "Always",
                        "name": "erp-wordpress-php-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "1",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "500m",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    }
                ],
                "dnsPolicy": "ClusterFirst",
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "terminationGracePeriodSeconds": 30
            }
        }
    },
    "status": {
        "conditions": [
            {
                "lastTransitionTime": "2022-06-07T01:43:49Z",
                "lastUpdateTime": "2022-06-07T01:43:49Z",
                "message": "Created new replica set \"erp-wordpress-deployment-7548bdf47f\"",
                "reason": "NewReplicaSetCreated",
                "status": "True",
                "type": "Progressing"
            },
            {
                "lastTransitionTime": "2022-06-07T01:43:49Z",
                "lastUpdateTime": "2022-06-07T01:43:49Z",
                "message": "Deployment does not have minimum availability.",
                "reason": "MinimumReplicasUnavailable",
                "status": "False",
                "type": "Available"
            },
            {
                "lastTransitionTime": "2022-06-07T01:43:49Z",
                "lastUpdateTime": "2022-06-07T01:43:49Z",
                "message": "pods \"erp-wordpress-deployment-7548bdf47f-ptsbc\" is forbidden: [maximum memory usage per Container is 2Gi, but limit is 8Gi, maximum memory usage per Pod is 4Gi, but limit is 9663676416]",
                "reason": "FailedCreate",
                "status": "True",
                "type": "ReplicaFailure"
            }
        ],
        "observedGeneration": 1,
        "unavailableReplicas": 1
    }
}
```

- step3. 删除deployment

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case5-pod-cpu-limit.yaml 
deployment.apps "erp-wordpress-deployment" deleted
```

### 1.4 kubernetes对整个namespace的CPU及memory实现资源限制

#### 1.4.1 ResourceQuota

[ResourceQuota](https://kubernetes.io/zh/docs/concepts/policy/resource-quotas/)对每个命名空间的资源消耗总量提供限制.它可以限制命名空间中某种类型的对象的总数目上限,也可以限制命名空间中的Pod可以使用的计算资源的总上限.

- 当用户在命名空间下创建资源(如Pod、Service等)时,Kubernetes的配额系统会跟踪集群的资源使用情况,以确保使用的资源用量不超过ResourceQuota中定义的硬性资源限额
- 如果资源创建或者更新请求违反了配额约束,那么该请求会报错(HTTP 403 FORBIDDEN),并在消息中给出有可能违反的约束
- 限定某个对象类型(如Pod、service)可创建对象的总数
- 限定某个对象类型可消耗的计算资源(CPU、内存)与存储资源(存储卷声明)总数

```
root@k8s-master-1:~/k8s-data/limit-case# vim case6-resourceQuota-erp.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case6-resourceQuota-erp.yaml
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota-erp
  namespace: erp
spec:
  # 硬限制
  hard:
    # 该namespace下所有处于running状态的Pod 其CPU需求总量不能超过该值
    requests.cpu: "20"
    # 该namespace下所有处于running状态的Pod 其CPU限额总量不能超过该值
    limits.cpu: "20"
    # 该namespace下所有处于running状态的Pod 其内存需求总量不能超过该值
    requests.memory: 100Gi
    # 该namespace下所有处于running状态的Pod 其内存限额总量不能超过该值
    limits.memory: 100Gi
    # 该namespace下所有处于running状态的Pod 其扩展资源的配额不能超过该值
    # 由于扩展资源无法超量分配 故没有必要在配额中对同一扩展资源指定requests和limits
    requests.nvidia.com/gpu: 4
    # 该namespace下所有PVC 其存储资源的需求总量不能超过该值
    requests.storage: 200Gi
    # 该namespace下 PVC的数量不能超过该值
    persistentvolumeclaims: "100"
    # 该namespace下 Pod的数量不能超过该值
    pods: "2"
    # 该namespace下 Service的数量不能超过该值
    services: "100"
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case6-resourceQuota-erp.yaml 
resourcequota/quota-erp created
root@k8s-master-1:~/k8s-data/limit-case# kubectl describe resourcequota quota-erp -n erp
Name:                    quota-erp
Namespace:               erp
Resource                 Used    Hard
--------                 ----    ----
limits.cpu               3900m   20
limits.memory            2304Mi  100Gi
persistentvolumeclaims   9       100
pods                     22      2
requests.cpu             3900m   20
requests.memory          2820Mi  100Gi
requests.nvidia.com/gpu  0       4
requests.storage         19Gi    200Gi
services                 15      100
```

#### 1.4.2 Pod副本数限制

- step1. 编写yaml文件,尝试创建pod

```
root@k8s-master-1:~/k8s-data/limit-case# vim case7-namespace-pod-limit-deployment.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case7-namespace-pod-limit-deployment.yaml
```

```
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-pod-limit-deployment-label
  name: erp-pod-limit-deployment
  namespace: erp
spec:
  replicas: 5
  selector:
    matchLabels:
      app: erp-pod-limit-deployment-selector
  template:
    metadata:
      labels:
        app: erp-pod-limit-deployment-selector
    spec:
      containers:
      - name: erp-nginx-container
        image: harbor.k8s.com/erp/nginx:1.22.0
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case7-namespace-pod-limit-deployment.yaml 
deployment.apps/erp-pod-limit-deployment created
```

- step2. 查看报错信息

```
root@k8s-master-1:~/k8s-data/limit-case# vim case7-namespace-pod-limit-deployment.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case7-namespace-pod-limit-deployment.yaml
```

```json
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-pod-limit-deployment-label
  name: erp-pod-limit-deployment
  namespace: erp
spec:
  replicas: 5
  selector:
    matchLabels:
      app: erp-pod-limit-deployment-selector
  template:
    metadata:
      labels:
        app: erp-pod-limit-deployment-selector
    spec:
      containers:
      - name: erp-nginx-container
        image: harbor.k8s.com/erp/nginx:1.22.0
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 500m
            memory: 512Mi
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case7-namespace-pod-limit-deployment.yaml 
deployment.apps/erp-pod-limit-deployment created
root@k8s-master-1:~/k8s-data/limit-case# kubectl get deployment erp-pod-limit-deployment -n erp -o json
{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "annotations": {
            "deployment.kubernetes.io/revision": "1",
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"erp-pod-limit-deployment-label\"},\"name\":\"erp-pod-limit-deployment\",\"namespace\":\"erp\"},\"spec\":{\"replicas\":5,\"selector\":{\"matchLabels\":{\"app\":\"erp-pod-limit-deployment-selector\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"erp-pod-limit-deployment-selector\"}},\"spec\":{\"containers\":[{\"image\":\"harbor.k8s.com/erp/nginx:1.22.0\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-nginx-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":1,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":\"500m\",\"memory\":\"512Mi\"}}}]}}}}\n"
        },
        "creationTimestamp": "2022-06-07T02:49:37Z",
        "generation": 1,
        "labels": {
            "app": "erp-pod-limit-deployment-label"
        },
        "name": "erp-pod-limit-deployment",
        "namespace": "erp",
        "resourceVersion": "1743074",
        "uid": "cc99faf2-8e4f-45cc-a28f-bebd2a2f6f9b"
    },
    "spec": {
        "progressDeadlineSeconds": 600,
        "replicas": 5,
        "revisionHistoryLimit": 10,
        "selector": {
            "matchLabels": {
                "app": "erp-pod-limit-deployment-selector"
            }
        },
        "strategy": {
            "rollingUpdate": {
                "maxSurge": "25%",
                "maxUnavailable": "25%"
            },
            "type": "RollingUpdate"
        },
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "erp-pod-limit-deployment-selector"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": "harbor.k8s.com/erp/nginx:1.22.0",
                        "imagePullPolicy": "Always",
                        "name": "erp-nginx-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "1",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "500m",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    }
                ],
                "dnsPolicy": "ClusterFirst",
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "terminationGracePeriodSeconds": 30
            }
        }
    },
    "status": {
        "conditions": [
            {
                "lastTransitionTime": "2022-06-07T02:49:37Z",
                "lastUpdateTime": "2022-06-07T02:49:37Z",
                "message": "Created new replica set \"erp-pod-limit-deployment-566f9884cc\"",
                "reason": "NewReplicaSetCreated",
                "status": "True",
                "type": "Progressing"
            },
            {
                "lastTransitionTime": "2022-06-07T02:49:37Z",
                "lastUpdateTime": "2022-06-07T02:49:37Z",
                "message": "Deployment does not have minimum availability.",
                "reason": "MinimumReplicasUnavailable",
                "status": "False",
                "type": "Available"
            },
            {
                "lastTransitionTime": "2022-06-07T02:49:37Z",
                "lastUpdateTime": "2022-06-07T02:49:37Z",
                "message": "pods \"erp-pod-limit-deployment-566f9884cc-7wdzj\" is forbidden: exceeded quota: quota-erp, requested: pods=1, used: pods=22, limited: pods=2",
                "reason": "FailedCreate",
                "status": "True",
                "type": "ReplicaFailure"
            }
        ],
        "observedGeneration": 1,
        "unavailableReplicas": 5
    }
}
```

- step3. 删除pod

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case7-namespace-pod-limit-deployment.yaml 
deployment.apps "erp-pod-limit-deployment" deleted
```

#### 1.4.3 CPU总计核心数限制

- step1. 修改ResourceQuota中对CPU总数的限制

```
root@k8s-master-1:~/k8s-data/limit-case# vim case6-resourceQuota-erp.yaml 
root@k8s-master-1:~/k8s-data/limit-case# cat case6-resourceQuota-erp.yaml
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota-erp
  namespace: erp
spec:
  # 硬限制
  hard:
    # 该namespace下所有处于running状态的Pod 其CPU需求总量不能超过该值
    requests.cpu: "1"
    # 该namespace下所有处于running状态的Pod 其CPU限额总量不能超过该值
    limits.cpu: "1"
    # 该namespace下所有处于running状态的Pod 其内存需求总量不能超过该值
    requests.memory: 100Gi
    # 该namespace下所有处于running状态的Pod 其内存限额总量不能超过该值
    limits.memory: 100Gi
    # 该namespace下所有处于running状态的Pod 其扩展资源的配额不能超过该值
    # 由于扩展资源无法超量分配 故没有必要在配额中对同一扩展资源指定requests和limits
    requests.nvidia.com/gpu: 4
    # 该namespace下所有PVC 其存储资源的需求总量不能超过该值
    requests.storage: 200Gi
    # 该namespace下 PVC的数量不能超过该值
    persistentvolumeclaims: "100"
    # 该namespace下 Pod的数量不能超过该值
    pods: "2"
    # 该namespace下 Service的数量不能超过该值
    services: "100"
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case6-resourceQuota-erp.yaml
resourcequota/quota-erp configured
root@k8s-master-1:~/k8s-data/limit-case# kubectl describe resourcequota quota-erp -n erp
Name:                    quota-erp
Namespace:               erp
Resource                 Used    Hard
--------                 ----    ----
limits.cpu               3900m   1
limits.memory            2304Mi  100Gi
persistentvolumeclaims   9       100
pods                     22      2
requests.cpu             3900m   1
requests.memory          2820Mi  100Gi
requests.nvidia.com/gpu  0       4
requests.storage         19Gi    200Gi
services                 15      100
```

- step2. 编写yaml文件,尝试创建pod

```
root@k8s-master-1:~/k8s-data/limit-case# vim case8-namespace-cpu-limit-deployment.yaml
root@k8s-master-1:~/k8s-data/limit-case# cat case8-namespace-cpu-limit-deployment.yaml
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  labels:
    app: erp-cpu-limit-deployment-label
  name: erp-cpu-limit-deployment
  namespace: erp
spec:
  replicas: 5
  selector:
    matchLabels:
      app: erp-cpu-limit-deployment-selector
  template:
    metadata:
      labels:
        app: erp-cpu-limit-deployment-selector
    spec:
      containers:
      - name: erp-nginx-container
        image: harbor.k8s.com/erp/nginx:1.22.0
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          protocol: TCP
          name: http
        resources:
          limits:
            cpu: 1
            memory: 1Gi
          requests:
            cpu: 1
            memory: 512Mi
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl apply -f case8-namespace-cpu-limit-deployment.yaml 
deployment.apps/erp-cpu-limit-deployment created
```

- step3. 查看报错信息

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get deployment erp-cpu-limit-deployment -n erp -o json
```

```json
{
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "annotations": {
            "deployment.kubernetes.io/revision": "1",
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"erp-cpu-limit-deployment-label\"},\"name\":\"erp-cpu-limit-deployment\",\"namespace\":\"erp\"},\"spec\":{\"replicas\":5,\"selector\":{\"matchLabels\":{\"app\":\"erp-cpu-limit-deployment-selector\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"erp-cpu-limit-deployment-selector\"}},\"spec\":{\"containers\":[{\"image\":\"harbor.k8s.com/erp/nginx:1.22.0\",\"imagePullPolicy\":\"Always\",\"name\":\"erp-nginx-container\",\"ports\":[{\"containerPort\":80,\"name\":\"http\",\"protocol\":\"TCP\"}],\"resources\":{\"limits\":{\"cpu\":1,\"memory\":\"1Gi\"},\"requests\":{\"cpu\":1,\"memory\":\"512Mi\"}}}]}}}}\n"
        },
        "creationTimestamp": "2022-06-07T03:00:03Z",
        "generation": 1,
        "labels": {
            "app": "erp-cpu-limit-deployment-label"
        },
        "name": "erp-cpu-limit-deployment",
        "namespace": "erp",
        "resourceVersion": "1744426",
        "uid": "c87825c8-70f5-42c6-9547-c03810054b38"
    },
    "spec": {
        "progressDeadlineSeconds": 600,
        "replicas": 5,
        "revisionHistoryLimit": 10,
        "selector": {
            "matchLabels": {
                "app": "erp-cpu-limit-deployment-selector"
            }
        },
        "strategy": {
            "rollingUpdate": {
                "maxSurge": "25%",
                "maxUnavailable": "25%"
            },
            "type": "RollingUpdate"
        },
        "template": {
            "metadata": {
                "creationTimestamp": null,
                "labels": {
                    "app": "erp-cpu-limit-deployment-selector"
                }
            },
            "spec": {
                "containers": [
                    {
                        "image": "harbor.k8s.com/erp/nginx:1.22.0",
                        "imagePullPolicy": "Always",
                        "name": "erp-nginx-container",
                        "ports": [
                            {
                                "containerPort": 80,
                                "name": "http",
                                "protocol": "TCP"
                            }
                        ],
                        "resources": {
                            "limits": {
                                "cpu": "1",
                                "memory": "1Gi"
                            },
                            "requests": {
                                "cpu": "1",
                                "memory": "512Mi"
                            }
                        },
                        "terminationMessagePath": "/dev/termination-log",
                        "terminationMessagePolicy": "File"
                    }
                ],
                "dnsPolicy": "ClusterFirst",
                "restartPolicy": "Always",
                "schedulerName": "default-scheduler",
                "securityContext": {},
                "terminationGracePeriodSeconds": 30
            }
        }
    },
    "status": {
        "conditions": [
            {
                "lastTransitionTime": "2022-06-07T03:00:03Z",
                "lastUpdateTime": "2022-06-07T03:00:03Z",
                "message": "Created new replica set \"erp-cpu-limit-deployment-687d9c9987\"",
                "reason": "NewReplicaSetCreated",
                "status": "True",
                "type": "Progressing"
            },
            {
                "lastTransitionTime": "2022-06-07T03:00:03Z",
                "lastUpdateTime": "2022-06-07T03:00:03Z",
                "message": "Deployment does not have minimum availability.",
                "reason": "MinimumReplicasUnavailable",
                "status": "False",
                "type": "Available"
            },
            {
                "lastTransitionTime": "2022-06-07T03:00:03Z",
                "lastUpdateTime": "2022-06-07T03:00:03Z",
                "message": "pods \"erp-cpu-limit-deployment-687d9c9987-tbhth\" is forbidden: exceeded quota: quota-erp, requested: limits.cpu=1,pods=1,requests.cpu=1, used: limits.cpu=3900m,pods=22,requests.cpu=3900m, limited: limits.cpu=1,pods=2,requests.cpu=1",
                "reason": "FailedCreate",
                "status": "True",
                "type": "ReplicaFailure"
            }
        ],
        "observedGeneration": 1,
        "unavailableReplicas": 5
    }
}
```

- step4. 删除deployment控制器

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl delete -f case8-namespace-cpu-limit-deployment.yaml 
deployment.apps "erp-cpu-limit-deployment" deleted
```

## PART2. Kubernetes鉴权与准入

[使用RBAC鉴权](https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/)

RBAC API声明了4种Kubernetes对象:

- Role:用于对指定的命名空间设置访问权限,在设置Role时,必须指定该Role所属的命名空间
- RoleBinding:用于将角色中定义的权限赋予给一个或一组用户.它包含若干主体(用户、组或服务账户)的列表和对这些主体所获得的角色的引用.RoleBinding用于在指定的命名空间中执行授权
- ClusterRole:同样也是用于设置访问权限,但其作用域为一个集群
- ClusterRoleBinding:用于将ClusterRole绑定到集群中的所有命名空间

更通俗的理解:可以认为Role是对Pod的访问控制;ClusterRole是对集群的访问控制.一般很少将ClusterRole授予出去

[鉴权概述](https://kubernetes.io/zh/docs/reference/access-authn-authz/authorization/#determine-the-request-verb):在Kubernetes中,你必须在鉴权(授予访问权限)之前进行身份验证(即登录).

### 2.1 在指定的namespace下创建账户

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl create serviceaccount erp-user1 -n erp
serviceaccount/erp-user1 created
```

```
root@k8s-master-1:~/k8s-data/limit-case# kubectl get serviceaccounts -n erp
NAME        SECRETS   AGE
default     1         42d
erp-user1   1         13s
```

### 2.2 创建规则

```
root@k8s-master-1:~/k8s-data/limit-case# cd ..
root@k8s-master-1:~/k8s-data# mkdir role
root@k8s-master-1:~/k8s-data# cd role/
root@k8s-master-1:~/k8s-data/role# vim erp-role.yaml
root@k8s-master-1:~/k8s-data/role# cat erp-role.yaml
```

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: erp
  # 后续通过Role对象的名称 绑定到对应账号
  name: erp-user1-role
rules:
  # 表示对要设定权限的资源对象的API版本要求
  # 例如:要对一个ingress做权限控制
  # 通过kubectl api-resources命令查看资源的版本
  # (即kubectl api-resources命令中的APIVERSION列)
  # 可知 ingress资源对象有2个版本的API:
  # extensions/v1beta1 和 networking.k8s.io/v1 
  # 此处写*则表示2种API组都可以
  # 若写""(空串)则表示使用core API group
- apiGroups: ["*"]
  # resources用于指定资源 即kubectl api-resources命令中的NAME列
  # 像如下形式的资源 指的是子资源 例如要控制对Pod日志的权限 则此处要写"pods/log"
  # 此处的"pods/exec"是一种用于在pod中执行命令的资源
  resources: ["pods/exec"]
  # 具体的权限 
  # get: 查看单个
  # list: 列出所有 
  # watch: 监控 
  # create: 创建
  # update: 更新
  # patch: 局部更新
  # delete: 删除单个
  # deletecollection: 删除集合
  # exec: 执行
  # proxy: 代理(不知道啥权限)
  # redirect: 重定向(不知道啥权限)
  verbs: ["get", "list", "watch", "create"]

- apiGroups: ["*"]
  resources: ["pods/log"]
  verbs: ["get", "watch", "list"]

- apiGroups: ["*"]
  resources: ["pods"]
  # 通常针对开发而言 给get list watch这3个权限就够了
  verbs: ["get", "list", "watch"]

  # 此处写apps/v1是因为deployment资源对象只有这么一个版本
- apiGroups: ["apps/v1"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list"]
```

```
root@k8s-master-1:~/k8s-data/role# kubectl apply -f erp-role.yaml 
role.rbac.authorization.k8s.io/erp-user1-role created
root@k8s-master-1:~/k8s-data/role# kubectl get role -n erp
NAME             CREATED AT
erp-user1-role   2022-06-07T19:07:04Z
root@k8s-master-1:~/k8s-data/role# kubectl describe role erp-user1-role -n erp
Name:         erp-user1-role
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources            Non-Resource URLs  Resource Names  Verbs
  ---------            -----------------  --------------  -----
  pods.*/exec          []                 []              [get list watch create]
  pods.*               []                 []              [get list watch]
  pods.*/log           []                 []              [get watch list]
  deployments.apps/v1  []                 []              [get watch list]
```

### 2.3 将规则与账户进行绑定

```
root@k8s-master-1:~/k8s-data/role# vim erp-user1-role-bind.yaml 
root@k8s-master-1:~/k8s-data/role# cat erp-user1-role-bind.yaml
```

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  # RoleBinding对象的名称
  name: erp-user1-role-bind
  namespace: erp
subjects:
  # 绑定到ServiceAccount对象
  # 该字段值可以为 User Group ServiceAccount
- kind: ServiceAccount
  name: erp-user1
  namespace: erp
roleRef:
  kind: Role
  # Role对象的名称
  name: erp-user1-role
  apiGroup: rbac.authorization.k8s.io
```

```
root@k8s-master-1:~/k8s-data/role# kubectl apply -f erp-user1-role-bind.yaml
rolebinding.rbac.authorization.k8s.io/erp-user1-role-bind created
root@k8s-master-1:~/k8s-data/role# kubectl get rolebinding -n erp
NAME                  ROLE                  AGE
erp-user1-role-bind   Role/erp-user1-role   11s
root@k8s-master-1:~/k8s-data/role# kubectl describe rolebinding erp-user1-role-bind -n erp
Name:         erp-user1-role-bind
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  erp-user1-role
Subjects:
  Kind            Name       Namespace
  ----            ----       ---------
  ServiceAccount  erp-user1  erp
```

### 2.4 获取token名称

ServiceAccount创建成功后,K8S会自动为该账户创建一个token.此处需要获取到这个token的名称,后续才能查看这个token的内容

```
root@k8s-master-1:~/k8s-data/role# kubectl get secret -n erp|grep erp-user1
erp-user1-token-xshcd   kubernetes.io/service-account-token   3      3h9m
```

### 2.5 使用token尝试登录

- step1. 获取token内容

```
root@k8s-master-1:~/k8s-data/role# kubectl describe secret erp-user1-token-xshcd -n erp
Name:         erp-user1-token-xshcd
Namespace:    erp
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: erp-user1
              kubernetes.io/service-account.uid: 62bbad78-e8f8-487d-8e6e-bb69c9ad9037

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1350 bytes
namespace:  3 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IkVvbUMxMF9hbGkwekNEUzM1QWs1engza1hMT0RxaDZXSUJ3cDJ6eFVXM3cifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJlcnAiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiZXJwLXVzZXIxLXRva2VuLXhzaGNkIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImVycC11c2VyMSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjYyYmJhZDc4LWU4ZjgtNDg3ZC04ZTZlLWJiNjljOWFkOTAzNyIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDplcnA6ZXJwLXVzZXIxIn0.fjZhRpyyVH8huJbRTERiL4KT7Qh-orz0-FWeNFy4LCbEo_6FQ9pb-BsH4IaoJe4qq_L14HB_dslYas8tAPbmAuQUtp6ML1RPwmCkoFy_P-Ny0m054Moy8CC4nWEg8Olii7wApXlv1GaraNWTAZr69MNAH86DH3mVS56iD498eEJ8Ef4rgnHUVBWsJg3eEaFwqNSNQeZi38qVtgtxYup8viftTVuPjcDngu9GGHxCxXJdtcTd1kzYpTTJZGEMhZpT4_1mawF4x8Q7xvBB4UyWB8jy9vnf8SiB1Onf0XptcG2B6ya-Jw12qPzUFW7Dt8zhWKS_UW2MWaDz1kKIxUHj9Q
```

- step2. 尝试使用该token登录

![尝试使用token登录](./img/尝试使用token登录.png)

![登录成功](./img/登录成功.png)

## PART3. 使用kube-config文件登录

### 3.1 创建csr文件

K8S的证书是自行签发的.csr文件用于申请证书.

```
root@k8s-master-1:~/k8s-data/role# vim erp-user1-csr.json
root@k8s-master-1:~/k8s-data/role# cat erp-user1-csr.json
```

```json
{
  "CN": "China",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
```

### 3.2 签发证书

#### 3.2.1 安装cfssl

kubeasz中自带了cfssl.此处只需要将kubeasz中的cfssl软连接到`/usr/bin`下即可,不需再次安装.

```
root@k8s-master-1:~/k8s-data/role# ln -sv /etc/kubeasz/bin/cfssl* /usr/bin/
'/usr/bin/cfssl' -> '/etc/kubeasz/bin/cfssl'
'/usr/bin/cfssl-certinfo' -> '/etc/kubeasz/bin/cfssl-certinfo'
'/usr/bin/cfssljson' -> '/etc/kubeasz/bin/cfssljson'
```

#### 3.2.2 查看K8S的证书

```
root@k8s-master-1:~/k8s-data/role# ll /etc/kubernetes/ssl/
total 40
drwxr-xr-x 2 root root 4096 Apr 24 00:25 ./
drwxr-xr-x 3 root root 4096 Apr 24 00:25 ../
-rw-r--r-- 1 root root 1675 Apr 24 00:25 aggregator-proxy-key.pem
-rw-r--r-- 1 root root 1383 Apr 24 00:25 aggregator-proxy.pem
-rw-r--r-- 1 root root 1679 Apr 24 00:25 ca-key.pem
-rw-r--r-- 1 root root 1350 Apr 24 00:25 ca.pem
-rw-r--r-- 1 root root 1679 Apr 24 00:25 kubelet-key.pem
-rw-r--r-- 1 root root 1452 Apr 24 00:25 kubelet.pem
-rw-r--r-- 1 root root 1679 Apr 24 00:25 kubernetes-key.pem
-rw-r--r-- 1 root root 1647 Apr 24 00:25 kubernetes.pem
```

#### 3.2.3 查看K8S集群的证书配置文件

```
root@k8s-master-1:~/k8s-data/role# ll /etc/kubeasz/clusters/k8s-my-cluster/ssl/ca-config.json 
-rw-r--r-- 1 root root 483 Apr 24 00:14 /etc/kubeasz/clusters/k8s-my-cluster/ssl/ca-config.json
```
#### 3.2.4 签发证书

```
root@k8s-master-1:~/k8s-data/role# cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem  -ca-key=/etc/kubernetes/ssl/ca-key.pem -config=/etc/kubeasz/clusters/k8s-my-cluster/ssl/ca-config.json -profile=kubernetes erp-user1-csr.json|cfssljson -bare  erp-user1
2022/06/08 03:46:08 [INFO] generate received request
2022/06/08 03:46:08 [INFO] received CSR
2022/06/08 03:46:08 [INFO] generating key: rsa-2048
2022/06/08 03:46:08 [INFO] encoded CSR
2022/06/08 03:46:08 [INFO] signed certificate with serial number 336419241779551091208839586706198109953291746775
2022/06/08 03:46:08 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
```

- `-ca`:K8S集群ca证书路径
- `-ca-key`:K8S集群key证书路径
- `-config`:K8S集群的ca配置文件的路径
- `-profile`:指定申请证书用的csr文件路径

```
root@k8s-master-1:~/k8s-data/role# ll
total 32
drwxr-xr-x  2 root root 4096 Jun  8 03:46 ./
drwxr-xr-x 16 root root 4096 Jun  8 03:06 ../
-rw-r--r--  1 root root 1628 Jun  8 03:06 erp-role.yaml
-rw-r--r--  1 root root  993 Jun  8 03:46 erp-user1.csr
-rw-r--r--  1 root root  218 Jun  8 03:35 erp-user1-csr.json
-rw-------  1 root root 1679 Jun  8 03:46 erp-user1-key.pem
-rw-r--r--  1 root root 1383 Jun  8 03:46 erp-user1.pem
-rw-r--r--  1 root root  406 Jun  8 03:16 erp-user1-role-bind.yaml
```

可以看到pem文件已经被生成了.

### 3.3 生成普通用户kubeconfig文件

使用kubeasz安装K8S时,默认将admin用户的kubeconfig文件生成到了`/root/.kube/config`中:

```
root@k8s-master-1:~/k8s-data/role# file /root/.kube/config 
/root/.kube/config: ASCII text, with very long lines
```

此处我们就需要自己生成kubeconfig文件了.

```
root@k8s-master-1:~/k8s-data/role# kubectl config set-cluster k8s-my-cluster --certificate-authority=/etc/kubernetes/ssl/ca.pem --embed-certs=true --server=https://192.168.0.118:6443 --kubeconfig=erp-user1.kubeconfig
Cluster "k8s-my-cluster" set.
root@k8s-master-1:~/k8s-data/role# ll
total 36
drwxr-xr-x  2 root root 4096 Jun  8 03:57 ./
drwxr-xr-x 16 root root 4096 Jun  8 03:06 ../
-rw-r--r--  1 root root 1628 Jun  8 03:06 erp-role.yaml
-rw-r--r--  1 root root  993 Jun  8 03:46 erp-user1.csr
-rw-r--r--  1 root root  218 Jun  8 03:35 erp-user1-csr.json
-rw-------  1 root root 1679 Jun  8 03:46 erp-user1-key.pem
-rw-------  1 root root 2007 Jun  8 03:57 erp-user1.kubeconfig
-rw-r--r--  1 root root 1383 Jun  8 03:46 erp-user1.pem
-rw-r--r--  1 root root  406 Jun  8 03:16 erp-user1-role-bind.yaml
```

- `--embed-certs=true`:嵌入证书信息到kubeconfig文件
- `--kubeconfig`:指定生成的kubeconfig文件的文件名
- `--server`:K8S APIServer的地址.注意,此处写的`192.168.0.118:6443`,是之前配置的haproxy的地址.并不是K8S master节点的APIServer地址.如果没配haproxy,那么你就写k8s master的APIServer的地址.

此时kubeconfig文件中只有一些基本信息:

```
root@k8s-master-1:~/k8s-data/role# cat erp-user1.kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUR1RENDQXFDZ0F3SUJBZ0lVY3lGY0ZoRitzdUo5QXgvS0E1UE9lUktxQ0tZd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOREl6TVRZd09UQXdXaGdQTWpFeU1qQXpNekF4TmpBNU1EQmFNR0V4Q3pBSkJnTlYKQkFZVEFrTk9NUkV3RHdZRFZRUUlFd2hJWVc1bldtaHZkVEVMTUFrR0ExVUVCeE1DV0ZNeEREQUtCZ05WQkFvVApBMnM0Y3pFUE1BMEdBMVVFQ3hNR1UzbHpkR1Z0TVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTRHcXgzS0FFRlVxTmpHbitLanduVlZxMXAyZUYKS1NsVXIxVkllUVdBaXgyMmlHTzVSeGhoWUg2V2J0Ui9EWERJUXljbUhJU3lqSUc1bnlaODFPWW9BQm1UdUJXNwpyelNOMEhRUDMySnpUYms2dkg5dkRSVmxxS055VE9rOWs5WWRtbVFTbGcrN2NmaGVmOEpvZlFGUnZvNjNIQkRDCkxiY0ZzcVd6a3FPLzRibkJrV2pSTG5jenV4NHBQSWVaMndQV0g0a00rMyt6V3Z4aE4ydEIrZ3pBbG9rSmpkUlQKOEdPaktSMFRWNHhUYy9QbzE0SWRMaUhlTmJvOGdTenZzRDRKRHpuSUFMUWNiN2YxdlRCRHBHNUNERTMrVjNZZApOcGt5Sit3aGQ0Uy9kWElKaUtjbW03enYzQ2ZST3BpcWkyTVAxMHJpOWlOUG84anF0a1ZQdUpMTkp3SURBUUFCCm8yWXdaREFPQmdOVkhROEJBZjhFQkFNQ0FRWXdFZ1lEVlIwVEFRSC9CQWd3QmdFQi93SUJBakFkQmdOVkhRNEUKRmdRVXU5ZWdEWGRjcXZVQWYyTzZYSW1tK3hUMlh1RXdId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNgpYSW1tK3hUMlh1RXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQ3dIaGpEMkxNOUcrTEEyOTN6VVIydURLa1hvClVVbitJbk5PQVhZZ1ZqQmZCajBMWHBrd2hVUzlHTWdSQnp4bVVWblk1L2l1SDVhMVV5bXFCTUt2ZWl3bkNXVEsKUUU5SXVHUWZnaWRKSEpyV2g3VHBBTWdUZmFNaWJBTmJCWW9hd1hlYVQ2Y3loYnZlSXRCMHA1UFVad09WaEsrQQppdTdKNmZlQ25ISTQ4ekZHMXRVOUI3bHBkbzZ5TElpRmNiSGdUM0NzRUwrMGlBVEJ6UmZPcndRS2ZBa2VyVVhxClpucVFlMVNIM09Ja0g2OEVIa1VjdDZXK2JTdnlwWTRXYjRZSHE0MWRXYTJZQVhMY3BaR1djTysyWDZGeDFwTnEKbFdkOFRqMjRtMEN0bXBzTmUyS0xqcktoK284WEtBby9mTkVNN1JMbUNMVG8xMTJ3MzljQVFEL1g0ZTQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.0.118:6443
  name: k8s-my-cluster
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null
```

### 3.4 设置客户端认证参数

- step1. 将生成的证书和K8S之前自动生成的证书放到一起

```
root@k8s-master-1:~/k8s-data/role# cp *.pem /etc/kubernetes/ssl/
root@k8s-master-1:~/k8s-data/role# ll /etc/kubernetes/ssl/
total 48
drwxr-xr-x 2 root root 4096 Jun  8 04:08 ./
drwxr-xr-x 3 root root 4096 Apr 24 00:25 ../
-rw-r--r-- 1 root root 1675 Apr 24 00:25 aggregator-proxy-key.pem
-rw-r--r-- 1 root root 1383 Apr 24 00:25 aggregator-proxy.pem
-rw-r--r-- 1 root root 1679 Apr 24 00:25 ca-key.pem
-rw-r--r-- 1 root root 1350 Apr 24 00:25 ca.pem
-rw------- 1 root root 1679 Jun  8 04:08 erp-user1-key.pem
-rw-r--r-- 1 root root 1383 Jun  8 04:08 erp-user1.pem
-rw-r--r-- 1 root root 1679 Apr 24 00:25 kubelet-key.pem
-rw-r--r-- 1 root root 1452 Apr 24 00:25 kubelet.pem
-rw-r--r-- 1 root root 1679 Apr 24 00:25 kubernetes-key.pem
-rw-r--r-- 1 root root 1647 Apr 24 00:25 kubernetes.pem
```

- step2. 填充认证参数到kubeconfig文件

```
root@k8s-master-1:~/k8s-data/role# kubectl config set-credentials erp-user1 \
> --client-certificate=/etc/kubernetes/ssl/erp-user1.pem \
> --client-key=/etc/kubernetes/ssl/erp-user1-key.pem \
> --embed-certs=true \
> --kubeconfig=erp-user1.kubeconfig
User "erp-user1" set.
```

- step3. 查看kubeconfig文件

```
root@k8s-master-1:~/k8s-data/role# cat erp-user1.kubeconfig 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUR1RENDQXFDZ0F3SUJBZ0lVY3lGY0ZoRitzdUo5QXgvS0E1UE9lUktxQ0tZd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOREl6TVRZd09UQXdXaGdQTWpFeU1qQXpNekF4TmpBNU1EQmFNR0V4Q3pBSkJnTlYKQkFZVEFrTk9NUkV3RHdZRFZRUUlFd2hJWVc1bldtaHZkVEVMTUFrR0ExVUVCeE1DV0ZNeEREQUtCZ05WQkFvVApBMnM0Y3pFUE1BMEdBMVVFQ3hNR1UzbHpkR1Z0TVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTRHcXgzS0FFRlVxTmpHbitLanduVlZxMXAyZUYKS1NsVXIxVkllUVdBaXgyMmlHTzVSeGhoWUg2V2J0Ui9EWERJUXljbUhJU3lqSUc1bnlaODFPWW9BQm1UdUJXNwpyelNOMEhRUDMySnpUYms2dkg5dkRSVmxxS055VE9rOWs5WWRtbVFTbGcrN2NmaGVmOEpvZlFGUnZvNjNIQkRDCkxiY0ZzcVd6a3FPLzRibkJrV2pSTG5jenV4NHBQSWVaMndQV0g0a00rMyt6V3Z4aE4ydEIrZ3pBbG9rSmpkUlQKOEdPaktSMFRWNHhUYy9QbzE0SWRMaUhlTmJvOGdTenZzRDRKRHpuSUFMUWNiN2YxdlRCRHBHNUNERTMrVjNZZApOcGt5Sit3aGQ0Uy9kWElKaUtjbW03enYzQ2ZST3BpcWkyTVAxMHJpOWlOUG84anF0a1ZQdUpMTkp3SURBUUFCCm8yWXdaREFPQmdOVkhROEJBZjhFQkFNQ0FRWXdFZ1lEVlIwVEFRSC9CQWd3QmdFQi93SUJBakFkQmdOVkhRNEUKRmdRVXU5ZWdEWGRjcXZVQWYyTzZYSW1tK3hUMlh1RXdId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNgpYSW1tK3hUMlh1RXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQ3dIaGpEMkxNOUcrTEEyOTN6VVIydURLa1hvClVVbitJbk5PQVhZZ1ZqQmZCajBMWHBrd2hVUzlHTWdSQnp4bVVWblk1L2l1SDVhMVV5bXFCTUt2ZWl3bkNXVEsKUUU5SXVHUWZnaWRKSEpyV2g3VHBBTWdUZmFNaWJBTmJCWW9hd1hlYVQ2Y3loYnZlSXRCMHA1UFVad09WaEsrQQppdTdKNmZlQ25ISTQ4ekZHMXRVOUI3bHBkbzZ5TElpRmNiSGdUM0NzRUwrMGlBVEJ6UmZPcndRS2ZBa2VyVVhxClpucVFlMVNIM09Ja0g2OEVIa1VjdDZXK2JTdnlwWTRXYjRZSHE0MWRXYTJZQVhMY3BaR1djTysyWDZGeDFwTnEKbFdkOFRqMjRtMEN0bXBzTmUyS0xqcktoK284WEtBby9mTkVNN1JMbUNMVG8xMTJ3MzljQVFEL1g0ZTQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.0.118:6443
  name: k8s-my-cluster
contexts: null
current-context: ""
kind: Config
preferences: {}
users:
- name: erp-user1
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUQwRENDQXJpZ0F3SUJBZ0lVT3UyUGY0eW9zRVRrRnlsTnlKcHJtUk4wZmRjd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOakEzTVRrME1UQXdXaGdQTWpBM01qQTFNalV4T1RReE1EQmFNR0F4Q3pBSkJnTlYKQkFZVEFrTk9NUkF3RGdZRFZRUUlFd2RDWldsS2FXNW5NUkF3RGdZRFZRUUhFd2RDWldsS2FXNW5NUXd3Q2dZRApWUVFLRXdOck9ITXhEekFOQmdOVkJBc1RCbE41YzNSbGJURU9NQXdHQTFVRUF4TUZRMmhwYm1Fd2dnRWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDeXl3cHZkTGRPbktQVVMxRTMxaTJLRVFQS1lScUQKQUR1VXVidVI4QzhnUFNHMDJ3SU50SmUyY0JIYkpxdURjUHFMd3JGZlZFdi9PcnovRmk4ZlErUm4reXRyckxLMAprblpkQTZ0THZJV3JNNFJ5Q3VGTWZOK0xCWDVKSTdVK3J0YVBIUEdmZWhIRVJUdjhiZnM1eG5iaTNCdnNCRDB3ClVMR01vcmJ0QlBHelNIaE1iT000WFkxOW5uaWc5V1ZyL2hqN2lxbHhNdlNJUjF6Z3lXeVg5SXJ3TkFSMTlSR04KdjE1c1hrVk1kZzFnUVRmcVJIL0FSSFdtbEUyUFJ6SzRMRC9iWlRXeUdFdXpzZk5xTkw0S1JBQ3YyL3dqWmVhVQpHVEN6eGwxM1BlaEZ1Y1kyaERlREN0bFVndGdDTlY1Z2ZzV2c2bERRV1JDK3R0ODBJUU0vRG9DcEFnTUJBQUdqCmZ6QjlNQTRHQTFVZER3RUIvd1FFQXdJRm9EQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBUVlJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFkQmdOVkhRNEVGZ1FVamJQUGEzc25heGd6Q3pHV04zenJYOEU3cTJZdwpId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNlhJbW0reFQyWHVFd0RRWUpLb1pJaHZjTkFRRUxCUUFECmdnRUJBRENNem9VVFpKU24xVTVkU2pvYk5NdFIrL0NZeEhDdUxNSmUrdGxsRkR0aFV2S3FzSzc0ZFpGN0RMcWwKM2QyZXVIZlRqSlVtbzVhUjQxR21zOUFMcDl0NW5HN2wzTVprcTlQclVuM2EwbkhWdFROT0s0emV5Rno3dlRNSQp3TUlhc1VxZHN3dXZjNlY2Tmw0M0htUU1ncHRjcjYwT1lSRnpweUhOWEZVWW0zaldMKzlQQUlmSDhJL0RLY3krCm1BemNBdVF4ajIzWWMvNHFWT09keWtJdGdQVlJNUC9TZENtNlhNRS9iQlRyblc5N2pjK3Q4N2V0aFVrNm0xclEKUzN5UUcwZ2REYmtvWHJwcG84RUVDeUFtc3ZGbm5kVHRNVjhBdWtFREpCSXBKNU5QazNNbnpnbzJmbkMxVS9kZApuaERXTWxDbEV4OFZidytGV0ZwWGp5dmsyNkU9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBc3NzS2IzUzNUcHlqMUV0Uk45WXRpaEVEeW1FYWd3QTdsTG03a2ZBdklEMGh0TnNDCkRiU1h0bkFSMnlhcmczRDZpOEt4WDFSTC96cTgveFl2SDBQa1ovc3JhNnl5dEpKMlhRT3JTN3lGcXpPRWNncmgKVEh6Zml3VitTU08xUHE3V2p4enhuM29SeEVVNy9HMzdPY1oyNHR3YjdBUTlNRkN4aktLMjdRVHhzMGg0VEd6agpPRjJOZlo1NG9QVmxhLzRZKzRxcGNUTDBpRWRjNE1sc2wvU0s4RFFFZGZVUmpiOWViRjVGVEhZTllFRTM2a1IvCndFUjFwcFJOajBjeXVDdy8yMlUxc2hoTHM3SHphalMrQ2tRQXI5djhJMlhtbEJrd3M4WmRkejNvUmJuR05vUTMKZ3dyWlZJTFlBalZlWUg3Rm9PcFEwRmtRdnJiZk5DRURQdzZBcVFJREFRQUJBb0lCQVFDajJlZHFWVEJZWHJ6VgpKV0Q5SnM3OUpMS3dtV1RPZ1R3WkJFMmRaTndMVTNxOFg2ajJIbmFhdndIZU1RWWxvemc1Tk9lUVVaU0VCclNGCm9UTDJHQ1lPRk9TcC9NNlpKVkJMMWJ6NTMzOHdjam9DdVczWHh1aW1ZeFprdU5DMDdVMjhRZTQ5RklXTHRWZFAKOHdxMDIraS81cS9BRC9KemdMLzEvbmhkcHBaS2thdHFUb0E3eElwVzZiNE5jOEN6VmJCVWtkNkd2VTVPWFBKQQpVUTFOUjhCdmlCRW1ySHJNZ1JnOGdWRWZtaVk3NXhZeldJSkdOY2tIZWVUSHl2V2xZWitFamYxU05Nc2NDd2tPCnRNVmJSektUNklOU2I4ejhXdDZRM0ZoK3VYczYyQnBDSGJYZGdsQUw1SHRUdy9pU29OaVdKVUlQWE1YU1lMOE4KaXVOcVNJVEJBb0dCQU5jMHRzQ0ZKQ1NPbExKTzU2bDVzTkpkUXQwcFRYbTlSaFQ4dE00RWJKWnFueUdrWXJ1RgpGYkhGQWY4ZjlvZVRRb1BTb1h3SWh3VmRCazhZMWtLa3pSZWVqVE92T3huTE4yVWdHeDlocHhKN0pSTlFnYVNBCkxZWUlJd0FnNi9xZnc0RGhZZXQ2dElzTGV0U3o3em9WWnJwT0pVTE13cHFLS3UvaHc4MHB2b01sQW9HQkFOU3YKVTFiWVgwQkYwZ1N4QXlkN2VRK0oxQjdEcVFqSW1xeHh0dldBbWZ5QkMxT29peFZ0dTc1dC83akxZdmxKUHpYVQpYVThNWkI1eG05cXZkTWp0cE42RjNHR3hXNXk4eWRsUlFNeXM0OTIwcUtBTElBQ2ZxT3dLTXpCN3pjQllsL3RUCjZCS1lnZ2dNYXV2TEZJYWtPU2h1YXBhdVhKY2RXU05RTlNQOUZkSTFBb0dCQUl4MVZVbjJIQTdZR0drQVl1Y1UKQzdwaE1FRFVza0pnckpzS0RKL2g5MVY5Slh0NXBROHEzMnYxWDBZNmdGY2dYK3RWMEJ2NkhOWDlUeDdVNFJNQwpLUEhmZzkxVjQwY0VnWlU1RFRyQUs2RStTb1orcHY3TXdlbVc2ZkV0aTVjNkt3bTFFSW4ydmx0NkZLTTdCVXB0CnFXeXprRkkyL2xTTEZWY1hqUW9jMHNFWkFvR0FJVW80RHpYYTR1S0sxdlVsK3o0V1d0cEYrM0xBdUlFOXhKUWcKQVJsYUFPM3A2ZlJOb05NR09lNVp3b0VEUXVXMklTVFdYaE1nY0t0enE2MGU2SHhaL0FLVDFpNittaS9xb0R0WgpteS9Na3QwK0w1N09LWXJVRSs0Y3lRLzN5bzJUYkdGYng5MWJMUXRVaVFmR2RMU3J4YXBTd0xjV0F3a3k5SllQClcweTM1NmtDZ1lBSlkwR2ZaVTFQMFRwZEZpZ2RCaTkwNTFrbjRlSVIvSndMc2QwR3B3UkFUYndwaFhESDEwZjIKR2RBcVJrcWRaYk9DSGhRVTZMcTU3YVNIWVpXbUlzUy9jN0dld21PWjZPZzZyT3FTRlA3Z3JnZC9VYVFpSGh3OQpVN3NDcllKWmxJNmMvbDJPR3c0eDNabnFhRHRiMXpIaXJ3bzYzRFZRdnZmb3I5UTM5OURlUnc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

可以看到,此时`contexts`字段值还是null

### 3.5 设置kubeconfig中的上下文参数

同一管理端上运行了多个K8S集群时,通过上下文区分不同集群.

```
root@k8s-master-1:~/k8s-data/role# kubectl config set-context k8s-my-cluster \
> --cluster=k8s-my-cluster \
> --user=erp-user1 \
> --namespace=erp \
> --kubeconfig=erp-user1.kubeconfig
Context "k8s-my-cluster" created.
```

```
root@k8s-master-1:~/k8s-data/role# cat erp-user1.kubeconfig 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUR1RENDQXFDZ0F3SUJBZ0lVY3lGY0ZoRitzdUo5QXgvS0E1UE9lUktxQ0tZd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOREl6TVRZd09UQXdXaGdQTWpFeU1qQXpNekF4TmpBNU1EQmFNR0V4Q3pBSkJnTlYKQkFZVEFrTk9NUkV3RHdZRFZRUUlFd2hJWVc1bldtaHZkVEVMTUFrR0ExVUVCeE1DV0ZNeEREQUtCZ05WQkFvVApBMnM0Y3pFUE1BMEdBMVVFQ3hNR1UzbHpkR1Z0TVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTRHcXgzS0FFRlVxTmpHbitLanduVlZxMXAyZUYKS1NsVXIxVkllUVdBaXgyMmlHTzVSeGhoWUg2V2J0Ui9EWERJUXljbUhJU3lqSUc1bnlaODFPWW9BQm1UdUJXNwpyelNOMEhRUDMySnpUYms2dkg5dkRSVmxxS055VE9rOWs5WWRtbVFTbGcrN2NmaGVmOEpvZlFGUnZvNjNIQkRDCkxiY0ZzcVd6a3FPLzRibkJrV2pSTG5jenV4NHBQSWVaMndQV0g0a00rMyt6V3Z4aE4ydEIrZ3pBbG9rSmpkUlQKOEdPaktSMFRWNHhUYy9QbzE0SWRMaUhlTmJvOGdTenZzRDRKRHpuSUFMUWNiN2YxdlRCRHBHNUNERTMrVjNZZApOcGt5Sit3aGQ0Uy9kWElKaUtjbW03enYzQ2ZST3BpcWkyTVAxMHJpOWlOUG84anF0a1ZQdUpMTkp3SURBUUFCCm8yWXdaREFPQmdOVkhROEJBZjhFQkFNQ0FRWXdFZ1lEVlIwVEFRSC9CQWd3QmdFQi93SUJBakFkQmdOVkhRNEUKRmdRVXU5ZWdEWGRjcXZVQWYyTzZYSW1tK3hUMlh1RXdId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNgpYSW1tK3hUMlh1RXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQ3dIaGpEMkxNOUcrTEEyOTN6VVIydURLa1hvClVVbitJbk5PQVhZZ1ZqQmZCajBMWHBrd2hVUzlHTWdSQnp4bVVWblk1L2l1SDVhMVV5bXFCTUt2ZWl3bkNXVEsKUUU5SXVHUWZnaWRKSEpyV2g3VHBBTWdUZmFNaWJBTmJCWW9hd1hlYVQ2Y3loYnZlSXRCMHA1UFVad09WaEsrQQppdTdKNmZlQ25ISTQ4ekZHMXRVOUI3bHBkbzZ5TElpRmNiSGdUM0NzRUwrMGlBVEJ6UmZPcndRS2ZBa2VyVVhxClpucVFlMVNIM09Ja0g2OEVIa1VjdDZXK2JTdnlwWTRXYjRZSHE0MWRXYTJZQVhMY3BaR1djTysyWDZGeDFwTnEKbFdkOFRqMjRtMEN0bXBzTmUyS0xqcktoK284WEtBby9mTkVNN1JMbUNMVG8xMTJ3MzljQVFEL1g0ZTQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.0.118:6443
  name: k8s-my-cluster
contexts:
- context:
    cluster: k8s-my-cluster
    namespace: erp
    user: erp-user1
  name: k8s-my-cluster
current-context: ""
kind: Config
preferences: {}
users:
- name: erp-user1
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUQwRENDQXJpZ0F3SUJBZ0lVT3UyUGY0eW9zRVRrRnlsTnlKcHJtUk4wZmRjd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOakEzTVRrME1UQXdXaGdQTWpBM01qQTFNalV4T1RReE1EQmFNR0F4Q3pBSkJnTlYKQkFZVEFrTk9NUkF3RGdZRFZRUUlFd2RDWldsS2FXNW5NUkF3RGdZRFZRUUhFd2RDWldsS2FXNW5NUXd3Q2dZRApWUVFLRXdOck9ITXhEekFOQmdOVkJBc1RCbE41YzNSbGJURU9NQXdHQTFVRUF4TUZRMmhwYm1Fd2dnRWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDeXl3cHZkTGRPbktQVVMxRTMxaTJLRVFQS1lScUQKQUR1VXVidVI4QzhnUFNHMDJ3SU50SmUyY0JIYkpxdURjUHFMd3JGZlZFdi9PcnovRmk4ZlErUm4reXRyckxLMAprblpkQTZ0THZJV3JNNFJ5Q3VGTWZOK0xCWDVKSTdVK3J0YVBIUEdmZWhIRVJUdjhiZnM1eG5iaTNCdnNCRDB3ClVMR01vcmJ0QlBHelNIaE1iT000WFkxOW5uaWc5V1ZyL2hqN2lxbHhNdlNJUjF6Z3lXeVg5SXJ3TkFSMTlSR04KdjE1c1hrVk1kZzFnUVRmcVJIL0FSSFdtbEUyUFJ6SzRMRC9iWlRXeUdFdXpzZk5xTkw0S1JBQ3YyL3dqWmVhVQpHVEN6eGwxM1BlaEZ1Y1kyaERlREN0bFVndGdDTlY1Z2ZzV2c2bERRV1JDK3R0ODBJUU0vRG9DcEFnTUJBQUdqCmZ6QjlNQTRHQTFVZER3RUIvd1FFQXdJRm9EQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBUVlJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFkQmdOVkhRNEVGZ1FVamJQUGEzc25heGd6Q3pHV04zenJYOEU3cTJZdwpId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNlhJbW0reFQyWHVFd0RRWUpLb1pJaHZjTkFRRUxCUUFECmdnRUJBRENNem9VVFpKU24xVTVkU2pvYk5NdFIrL0NZeEhDdUxNSmUrdGxsRkR0aFV2S3FzSzc0ZFpGN0RMcWwKM2QyZXVIZlRqSlVtbzVhUjQxR21zOUFMcDl0NW5HN2wzTVprcTlQclVuM2EwbkhWdFROT0s0emV5Rno3dlRNSQp3TUlhc1VxZHN3dXZjNlY2Tmw0M0htUU1ncHRjcjYwT1lSRnpweUhOWEZVWW0zaldMKzlQQUlmSDhJL0RLY3krCm1BemNBdVF4ajIzWWMvNHFWT09keWtJdGdQVlJNUC9TZENtNlhNRS9iQlRyblc5N2pjK3Q4N2V0aFVrNm0xclEKUzN5UUcwZ2REYmtvWHJwcG84RUVDeUFtc3ZGbm5kVHRNVjhBdWtFREpCSXBKNU5QazNNbnpnbzJmbkMxVS9kZApuaERXTWxDbEV4OFZidytGV0ZwWGp5dmsyNkU9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBc3NzS2IzUzNUcHlqMUV0Uk45WXRpaEVEeW1FYWd3QTdsTG03a2ZBdklEMGh0TnNDCkRiU1h0bkFSMnlhcmczRDZpOEt4WDFSTC96cTgveFl2SDBQa1ovc3JhNnl5dEpKMlhRT3JTN3lGcXpPRWNncmgKVEh6Zml3VitTU08xUHE3V2p4enhuM29SeEVVNy9HMzdPY1oyNHR3YjdBUTlNRkN4aktLMjdRVHhzMGg0VEd6agpPRjJOZlo1NG9QVmxhLzRZKzRxcGNUTDBpRWRjNE1sc2wvU0s4RFFFZGZVUmpiOWViRjVGVEhZTllFRTM2a1IvCndFUjFwcFJOajBjeXVDdy8yMlUxc2hoTHM3SHphalMrQ2tRQXI5djhJMlhtbEJrd3M4WmRkejNvUmJuR05vUTMKZ3dyWlZJTFlBalZlWUg3Rm9PcFEwRmtRdnJiZk5DRURQdzZBcVFJREFRQUJBb0lCQVFDajJlZHFWVEJZWHJ6VgpKV0Q5SnM3OUpMS3dtV1RPZ1R3WkJFMmRaTndMVTNxOFg2ajJIbmFhdndIZU1RWWxvemc1Tk9lUVVaU0VCclNGCm9UTDJHQ1lPRk9TcC9NNlpKVkJMMWJ6NTMzOHdjam9DdVczWHh1aW1ZeFprdU5DMDdVMjhRZTQ5RklXTHRWZFAKOHdxMDIraS81cS9BRC9KemdMLzEvbmhkcHBaS2thdHFUb0E3eElwVzZiNE5jOEN6VmJCVWtkNkd2VTVPWFBKQQpVUTFOUjhCdmlCRW1ySHJNZ1JnOGdWRWZtaVk3NXhZeldJSkdOY2tIZWVUSHl2V2xZWitFamYxU05Nc2NDd2tPCnRNVmJSektUNklOU2I4ejhXdDZRM0ZoK3VYczYyQnBDSGJYZGdsQUw1SHRUdy9pU29OaVdKVUlQWE1YU1lMOE4KaXVOcVNJVEJBb0dCQU5jMHRzQ0ZKQ1NPbExKTzU2bDVzTkpkUXQwcFRYbTlSaFQ4dE00RWJKWnFueUdrWXJ1RgpGYkhGQWY4ZjlvZVRRb1BTb1h3SWh3VmRCazhZMWtLa3pSZWVqVE92T3huTE4yVWdHeDlocHhKN0pSTlFnYVNBCkxZWUlJd0FnNi9xZnc0RGhZZXQ2dElzTGV0U3o3em9WWnJwT0pVTE13cHFLS3UvaHc4MHB2b01sQW9HQkFOU3YKVTFiWVgwQkYwZ1N4QXlkN2VRK0oxQjdEcVFqSW1xeHh0dldBbWZ5QkMxT29peFZ0dTc1dC83akxZdmxKUHpYVQpYVThNWkI1eG05cXZkTWp0cE42RjNHR3hXNXk4eWRsUlFNeXM0OTIwcUtBTElBQ2ZxT3dLTXpCN3pjQllsL3RUCjZCS1lnZ2dNYXV2TEZJYWtPU2h1YXBhdVhKY2RXU05RTlNQOUZkSTFBb0dCQUl4MVZVbjJIQTdZR0drQVl1Y1UKQzdwaE1FRFVza0pnckpzS0RKL2g5MVY5Slh0NXBROHEzMnYxWDBZNmdGY2dYK3RWMEJ2NkhOWDlUeDdVNFJNQwpLUEhmZzkxVjQwY0VnWlU1RFRyQUs2RStTb1orcHY3TXdlbVc2ZkV0aTVjNkt3bTFFSW4ydmx0NkZLTTdCVXB0CnFXeXprRkkyL2xTTEZWY1hqUW9jMHNFWkFvR0FJVW80RHpYYTR1S0sxdlVsK3o0V1d0cEYrM0xBdUlFOXhKUWcKQVJsYUFPM3A2ZlJOb05NR09lNVp3b0VEUXVXMklTVFdYaE1nY0t0enE2MGU2SHhaL0FLVDFpNittaS9xb0R0WgpteS9Na3QwK0w1N09LWXJVRSs0Y3lRLzN5bzJUYkdGYng5MWJMUXRVaVFmR2RMU3J4YXBTd0xjV0F3a3k5SllQClcweTM1NmtDZ1lBSlkwR2ZaVTFQMFRwZEZpZ2RCaTkwNTFrbjRlSVIvSndMc2QwR3B3UkFUYndwaFhESDEwZjIKR2RBcVJrcWRaYk9DSGhRVTZMcTU3YVNIWVpXbUlzUy9jN0dld21PWjZPZzZyT3FTRlA3Z3JnZC9VYVFpSGh3OQpVN3NDcllKWmxJNmMvbDJPR3c0eDNabnFhRHRiMXpIaXJ3bzYzRFZRdnZmb3I5UTM5OURlUnc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

可以看到`contexts`字段中已经有了集群信息了.但`current-context`字段还是空的

### 3.6 设置默认上下文

```
root@k8s-master-1:~/k8s-data/role# kubectl config use-context k8s-my-cluster --kubeconfig=erp-user1.kubeconfig
Switched to context "k8s-my-cluster".
```

```
root@k8s-master-1:~/k8s-data/role# cat erp-user1.kubeconfig 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUR1RENDQXFDZ0F3SUJBZ0lVY3lGY0ZoRitzdUo5QXgvS0E1UE9lUktxQ0tZd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOREl6TVRZd09UQXdXaGdQTWpFeU1qQXpNekF4TmpBNU1EQmFNR0V4Q3pBSkJnTlYKQkFZVEFrTk9NUkV3RHdZRFZRUUlFd2hJWVc1bldtaHZkVEVMTUFrR0ExVUVCeE1DV0ZNeEREQUtCZ05WQkFvVApBMnM0Y3pFUE1BMEdBMVVFQ3hNR1UzbHpkR1Z0TVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTRHcXgzS0FFRlVxTmpHbitLanduVlZxMXAyZUYKS1NsVXIxVkllUVdBaXgyMmlHTzVSeGhoWUg2V2J0Ui9EWERJUXljbUhJU3lqSUc1bnlaODFPWW9BQm1UdUJXNwpyelNOMEhRUDMySnpUYms2dkg5dkRSVmxxS055VE9rOWs5WWRtbVFTbGcrN2NmaGVmOEpvZlFGUnZvNjNIQkRDCkxiY0ZzcVd6a3FPLzRibkJrV2pSTG5jenV4NHBQSWVaMndQV0g0a00rMyt6V3Z4aE4ydEIrZ3pBbG9rSmpkUlQKOEdPaktSMFRWNHhUYy9QbzE0SWRMaUhlTmJvOGdTenZzRDRKRHpuSUFMUWNiN2YxdlRCRHBHNUNERTMrVjNZZApOcGt5Sit3aGQ0Uy9kWElKaUtjbW03enYzQ2ZST3BpcWkyTVAxMHJpOWlOUG84anF0a1ZQdUpMTkp3SURBUUFCCm8yWXdaREFPQmdOVkhROEJBZjhFQkFNQ0FRWXdFZ1lEVlIwVEFRSC9CQWd3QmdFQi93SUJBakFkQmdOVkhRNEUKRmdRVXU5ZWdEWGRjcXZVQWYyTzZYSW1tK3hUMlh1RXdId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNgpYSW1tK3hUMlh1RXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQ3dIaGpEMkxNOUcrTEEyOTN6VVIydURLa1hvClVVbitJbk5PQVhZZ1ZqQmZCajBMWHBrd2hVUzlHTWdSQnp4bVVWblk1L2l1SDVhMVV5bXFCTUt2ZWl3bkNXVEsKUUU5SXVHUWZnaWRKSEpyV2g3VHBBTWdUZmFNaWJBTmJCWW9hd1hlYVQ2Y3loYnZlSXRCMHA1UFVad09WaEsrQQppdTdKNmZlQ25ISTQ4ekZHMXRVOUI3bHBkbzZ5TElpRmNiSGdUM0NzRUwrMGlBVEJ6UmZPcndRS2ZBa2VyVVhxClpucVFlMVNIM09Ja0g2OEVIa1VjdDZXK2JTdnlwWTRXYjRZSHE0MWRXYTJZQVhMY3BaR1djTysyWDZGeDFwTnEKbFdkOFRqMjRtMEN0bXBzTmUyS0xqcktoK284WEtBby9mTkVNN1JMbUNMVG8xMTJ3MzljQVFEL1g0ZTQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.0.118:6443
  name: k8s-my-cluster
contexts:
- context:
    cluster: k8s-my-cluster
    namespace: erp
    user: erp-user1
  name: k8s-my-cluster
current-context: k8s-my-cluster
kind: Config
preferences: {}
users:
- name: erp-user1
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUQwRENDQXJpZ0F3SUJBZ0lVT3UyUGY0eW9zRVRrRnlsTnlKcHJtUk4wZmRjd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOakEzTVRrME1UQXdXaGdQTWpBM01qQTFNalV4T1RReE1EQmFNR0F4Q3pBSkJnTlYKQkFZVEFrTk9NUkF3RGdZRFZRUUlFd2RDWldsS2FXNW5NUkF3RGdZRFZRUUhFd2RDWldsS2FXNW5NUXd3Q2dZRApWUVFLRXdOck9ITXhEekFOQmdOVkJBc1RCbE41YzNSbGJURU9NQXdHQTFVRUF4TUZRMmhwYm1Fd2dnRWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDeXl3cHZkTGRPbktQVVMxRTMxaTJLRVFQS1lScUQKQUR1VXVidVI4QzhnUFNHMDJ3SU50SmUyY0JIYkpxdURjUHFMd3JGZlZFdi9PcnovRmk4ZlErUm4reXRyckxLMAprblpkQTZ0THZJV3JNNFJ5Q3VGTWZOK0xCWDVKSTdVK3J0YVBIUEdmZWhIRVJUdjhiZnM1eG5iaTNCdnNCRDB3ClVMR01vcmJ0QlBHelNIaE1iT000WFkxOW5uaWc5V1ZyL2hqN2lxbHhNdlNJUjF6Z3lXeVg5SXJ3TkFSMTlSR04KdjE1c1hrVk1kZzFnUVRmcVJIL0FSSFdtbEUyUFJ6SzRMRC9iWlRXeUdFdXpzZk5xTkw0S1JBQ3YyL3dqWmVhVQpHVEN6eGwxM1BlaEZ1Y1kyaERlREN0bFVndGdDTlY1Z2ZzV2c2bERRV1JDK3R0ODBJUU0vRG9DcEFnTUJBQUdqCmZ6QjlNQTRHQTFVZER3RUIvd1FFQXdJRm9EQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBUVlJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFkQmdOVkhRNEVGZ1FVamJQUGEzc25heGd6Q3pHV04zenJYOEU3cTJZdwpId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNlhJbW0reFQyWHVFd0RRWUpLb1pJaHZjTkFRRUxCUUFECmdnRUJBRENNem9VVFpKU24xVTVkU2pvYk5NdFIrL0NZeEhDdUxNSmUrdGxsRkR0aFV2S3FzSzc0ZFpGN0RMcWwKM2QyZXVIZlRqSlVtbzVhUjQxR21zOUFMcDl0NW5HN2wzTVprcTlQclVuM2EwbkhWdFROT0s0emV5Rno3dlRNSQp3TUlhc1VxZHN3dXZjNlY2Tmw0M0htUU1ncHRjcjYwT1lSRnpweUhOWEZVWW0zaldMKzlQQUlmSDhJL0RLY3krCm1BemNBdVF4ajIzWWMvNHFWT09keWtJdGdQVlJNUC9TZENtNlhNRS9iQlRyblc5N2pjK3Q4N2V0aFVrNm0xclEKUzN5UUcwZ2REYmtvWHJwcG84RUVDeUFtc3ZGbm5kVHRNVjhBdWtFREpCSXBKNU5QazNNbnpnbzJmbkMxVS9kZApuaERXTWxDbEV4OFZidytGV0ZwWGp5dmsyNkU9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBc3NzS2IzUzNUcHlqMUV0Uk45WXRpaEVEeW1FYWd3QTdsTG03a2ZBdklEMGh0TnNDCkRiU1h0bkFSMnlhcmczRDZpOEt4WDFSTC96cTgveFl2SDBQa1ovc3JhNnl5dEpKMlhRT3JTN3lGcXpPRWNncmgKVEh6Zml3VitTU08xUHE3V2p4enhuM29SeEVVNy9HMzdPY1oyNHR3YjdBUTlNRkN4aktLMjdRVHhzMGg0VEd6agpPRjJOZlo1NG9QVmxhLzRZKzRxcGNUTDBpRWRjNE1sc2wvU0s4RFFFZGZVUmpiOWViRjVGVEhZTllFRTM2a1IvCndFUjFwcFJOajBjeXVDdy8yMlUxc2hoTHM3SHphalMrQ2tRQXI5djhJMlhtbEJrd3M4WmRkejNvUmJuR05vUTMKZ3dyWlZJTFlBalZlWUg3Rm9PcFEwRmtRdnJiZk5DRURQdzZBcVFJREFRQUJBb0lCQVFDajJlZHFWVEJZWHJ6VgpKV0Q5SnM3OUpMS3dtV1RPZ1R3WkJFMmRaTndMVTNxOFg2ajJIbmFhdndIZU1RWWxvemc1Tk9lUVVaU0VCclNGCm9UTDJHQ1lPRk9TcC9NNlpKVkJMMWJ6NTMzOHdjam9DdVczWHh1aW1ZeFprdU5DMDdVMjhRZTQ5RklXTHRWZFAKOHdxMDIraS81cS9BRC9KemdMLzEvbmhkcHBaS2thdHFUb0E3eElwVzZiNE5jOEN6VmJCVWtkNkd2VTVPWFBKQQpVUTFOUjhCdmlCRW1ySHJNZ1JnOGdWRWZtaVk3NXhZeldJSkdOY2tIZWVUSHl2V2xZWitFamYxU05Nc2NDd2tPCnRNVmJSektUNklOU2I4ejhXdDZRM0ZoK3VYczYyQnBDSGJYZGdsQUw1SHRUdy9pU29OaVdKVUlQWE1YU1lMOE4KaXVOcVNJVEJBb0dCQU5jMHRzQ0ZKQ1NPbExKTzU2bDVzTkpkUXQwcFRYbTlSaFQ4dE00RWJKWnFueUdrWXJ1RgpGYkhGQWY4ZjlvZVRRb1BTb1h3SWh3VmRCazhZMWtLa3pSZWVqVE92T3huTE4yVWdHeDlocHhKN0pSTlFnYVNBCkxZWUlJd0FnNi9xZnc0RGhZZXQ2dElzTGV0U3o3em9WWnJwT0pVTE13cHFLS3UvaHc4MHB2b01sQW9HQkFOU3YKVTFiWVgwQkYwZ1N4QXlkN2VRK0oxQjdEcVFqSW1xeHh0dldBbWZ5QkMxT29peFZ0dTc1dC83akxZdmxKUHpYVQpYVThNWkI1eG05cXZkTWp0cE42RjNHR3hXNXk4eWRsUlFNeXM0OTIwcUtBTElBQ2ZxT3dLTXpCN3pjQllsL3RUCjZCS1lnZ2dNYXV2TEZJYWtPU2h1YXBhdVhKY2RXU05RTlNQOUZkSTFBb0dCQUl4MVZVbjJIQTdZR0drQVl1Y1UKQzdwaE1FRFVza0pnckpzS0RKL2g5MVY5Slh0NXBROHEzMnYxWDBZNmdGY2dYK3RWMEJ2NkhOWDlUeDdVNFJNQwpLUEhmZzkxVjQwY0VnWlU1RFRyQUs2RStTb1orcHY3TXdlbVc2ZkV0aTVjNkt3bTFFSW4ydmx0NkZLTTdCVXB0CnFXeXprRkkyL2xTTEZWY1hqUW9jMHNFWkFvR0FJVW80RHpYYTR1S0sxdlVsK3o0V1d0cEYrM0xBdUlFOXhKUWcKQVJsYUFPM3A2ZlJOb05NR09lNVp3b0VEUXVXMklTVFdYaE1nY0t0enE2MGU2SHhaL0FLVDFpNittaS9xb0R0WgpteS9Na3QwK0w1N09LWXJVRSs0Y3lRLzN5bzJUYkdGYng5MWJMUXRVaVFmR2RMU3J4YXBTd0xjV0F3a3k5SllQClcweTM1NmtDZ1lBSlkwR2ZaVTFQMFRwZEZpZ2RCaTkwNTFrbjRlSVIvSndMc2QwR3B3UkFUYndwaFhESDEwZjIKR2RBcVJrcWRaYk9DSGhRVTZMcTU3YVNIWVpXbUlzUy9jN0dld21PWjZPZzZyT3FTRlA3Z3JnZC9VYVFpSGh3OQpVN3NDcllKWmxJNmMvbDJPR3c0eDNabnFhRHRiMXpIaXJ3bzYzRFZRdnZmb3I5UTM5OURlUnc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

可以看到,此时`current-context`字段也有信息了.

### 3.7 获取token

```
root@k8s-master-1:~/k8s-data/role# kubectl get secrets -n erp
NAME                    TYPE                                  DATA   AGE
default-token-td2cn     kubernetes.io/service-account-token   3      42d
erp-user1-token-xshcd   kubernetes.io/service-account-token   3      4h12m
mobile-tls-secret       Opaque                                2      15d
nginx-tls-secret        Opaque                                2      15d
root@k8s-master-1:~/k8s-data/role# kubectl get secrets -n erp|grep erp-user1
erp-user1-token-xshcd   kubernetes.io/service-account-token   3      4h12m
root@k8s-master-1:~/k8s-data/role# kubectl describe secret erp-user1-token-xshcd -n erp
Name:         erp-user1-token-xshcd
Namespace:    erp
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: erp-user1
              kubernetes.io/service-account.uid: 62bbad78-e8f8-487d-8e6e-bb69c9ad9037

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1350 bytes
namespace:  3 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IkVvbUMxMF9hbGkwekNEUzM1QWs1engza1hMT0RxaDZXSUJ3cDJ6eFVXM3cifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJlcnAiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiZXJwLXVzZXIxLXRva2VuLXhzaGNkIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImVycC11c2VyMSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjYyYmJhZDc4LWU4ZjgtNDg3ZC04ZTZlLWJiNjljOWFkOTAzNyIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDplcnA6ZXJwLXVzZXIxIn0.fjZhRpyyVH8huJbRTERiL4KT7Qh-orz0-FWeNFy4LCbEo_6FQ9pb-BsH4IaoJe4qq_L14HB_dslYas8tAPbmAuQUtp6ML1RPwmCkoFy_P-Ny0m054Moy8CC4nWEg8Olii7wApXlv1GaraNWTAZr69MNAH86DH3mVS56iD498eEJ8Ef4rgnHUVBWsJg3eEaFwqNSNQeZi38qVtgtxYup8viftTVuPjcDngu9GGHxCxXJdtcTd1kzYpTTJZGEMhZpT4_1mawF4x8Q7xvBB4UyWB8jy9vnf8SiB1Onf0XptcG2B6ya-Jw12qPzUFW7Dt8zhWKS_UW2MWaDz1kKIxUHj9Q
```

### 3.8 将token信息写入到kubeconfig文件中

```
root@k8s-master-1:~/k8s-data/role# vim erp-user1.kubeconfig 
root@k8s-master-1:~/k8s-data/role# cat erp-user1.kubeconfig
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUR1RENDQXFDZ0F3SUJBZ0lVY3lGY0ZoRitzdUo5QXgvS0E1UE9lUktxQ0tZd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOREl6TVRZd09UQXdXaGdQTWpFeU1qQXpNekF4TmpBNU1EQmFNR0V4Q3pBSkJnTlYKQkFZVEFrTk9NUkV3RHdZRFZRUUlFd2hJWVc1bldtaHZkVEVMTUFrR0ExVUVCeE1DV0ZNeEREQUtCZ05WQkFvVApBMnM0Y3pFUE1BMEdBMVVFQ3hNR1UzbHpkR1Z0TVJNd0VRWURWUVFERXdwcmRXSmxjbTVsZEdWek1JSUJJakFOCkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTRHcXgzS0FFRlVxTmpHbitLanduVlZxMXAyZUYKS1NsVXIxVkllUVdBaXgyMmlHTzVSeGhoWUg2V2J0Ui9EWERJUXljbUhJU3lqSUc1bnlaODFPWW9BQm1UdUJXNwpyelNOMEhRUDMySnpUYms2dkg5dkRSVmxxS055VE9rOWs5WWRtbVFTbGcrN2NmaGVmOEpvZlFGUnZvNjNIQkRDCkxiY0ZzcVd6a3FPLzRibkJrV2pSTG5jenV4NHBQSWVaMndQV0g0a00rMyt6V3Z4aE4ydEIrZ3pBbG9rSmpkUlQKOEdPaktSMFRWNHhUYy9QbzE0SWRMaUhlTmJvOGdTenZzRDRKRHpuSUFMUWNiN2YxdlRCRHBHNUNERTMrVjNZZApOcGt5Sit3aGQ0Uy9kWElKaUtjbW03enYzQ2ZST3BpcWkyTVAxMHJpOWlOUG84anF0a1ZQdUpMTkp3SURBUUFCCm8yWXdaREFPQmdOVkhROEJBZjhFQkFNQ0FRWXdFZ1lEVlIwVEFRSC9CQWd3QmdFQi93SUJBakFkQmdOVkhRNEUKRmdRVXU5ZWdEWGRjcXZVQWYyTzZYSW1tK3hUMlh1RXdId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNgpYSW1tK3hUMlh1RXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBQ3dIaGpEMkxNOUcrTEEyOTN6VVIydURLa1hvClVVbitJbk5PQVhZZ1ZqQmZCajBMWHBrd2hVUzlHTWdSQnp4bVVWblk1L2l1SDVhMVV5bXFCTUt2ZWl3bkNXVEsKUUU5SXVHUWZnaWRKSEpyV2g3VHBBTWdUZmFNaWJBTmJCWW9hd1hlYVQ2Y3loYnZlSXRCMHA1UFVad09WaEsrQQppdTdKNmZlQ25ISTQ4ekZHMXRVOUI3bHBkbzZ5TElpRmNiSGdUM0NzRUwrMGlBVEJ6UmZPcndRS2ZBa2VyVVhxClpucVFlMVNIM09Ja0g2OEVIa1VjdDZXK2JTdnlwWTRXYjRZSHE0MWRXYTJZQVhMY3BaR1djTysyWDZGeDFwTnEKbFdkOFRqMjRtMEN0bXBzTmUyS0xqcktoK284WEtBby9mTkVNN1JMbUNMVG8xMTJ3MzljQVFEL1g0ZTQ9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.0.118:6443
  name: k8s-my-cluster
contexts:
- context:
    cluster: k8s-my-cluster
    namespace: erp
    user: erp-user1
  name: k8s-my-cluster
current-context: k8s-my-cluster
kind: Config
preferences: {}
users:
- name: erp-user1
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUQwRENDQXJpZ0F3SUJBZ0lVT3UyUGY0eW9zRVRrRnlsTnlKcHJtUk4wZmRjd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1lURUxNQWtHQTFVRUJoTUNRMDR4RVRBUEJnTlZCQWdUQ0VoaGJtZGFhRzkxTVFzd0NRWURWUVFIRXdKWQpVekVNTUFvR0ExVUVDaE1EYXpoek1ROHdEUVlEVlFRTEV3WlRlWE4wWlcweEV6QVJCZ05WQkFNVENtdDFZbVZ5CmJtVjBaWE13SUJjTk1qSXdOakEzTVRrME1UQXdXaGdQTWpBM01qQTFNalV4T1RReE1EQmFNR0F4Q3pBSkJnTlYKQkFZVEFrTk9NUkF3RGdZRFZRUUlFd2RDWldsS2FXNW5NUkF3RGdZRFZRUUhFd2RDWldsS2FXNW5NUXd3Q2dZRApWUVFLRXdOck9ITXhEekFOQmdOVkJBc1RCbE41YzNSbGJURU9NQXdHQTFVRUF4TUZRMmhwYm1Fd2dnRWlNQTBHCkNTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDeXl3cHZkTGRPbktQVVMxRTMxaTJLRVFQS1lScUQKQUR1VXVidVI4QzhnUFNHMDJ3SU50SmUyY0JIYkpxdURjUHFMd3JGZlZFdi9PcnovRmk4ZlErUm4reXRyckxLMAprblpkQTZ0THZJV3JNNFJ5Q3VGTWZOK0xCWDVKSTdVK3J0YVBIUEdmZWhIRVJUdjhiZnM1eG5iaTNCdnNCRDB3ClVMR01vcmJ0QlBHelNIaE1iT000WFkxOW5uaWc5V1ZyL2hqN2lxbHhNdlNJUjF6Z3lXeVg5SXJ3TkFSMTlSR04KdjE1c1hrVk1kZzFnUVRmcVJIL0FSSFdtbEUyUFJ6SzRMRC9iWlRXeUdFdXpzZk5xTkw0S1JBQ3YyL3dqWmVhVQpHVEN6eGwxM1BlaEZ1Y1kyaERlREN0bFVndGdDTlY1Z2ZzV2c2bERRV1JDK3R0ODBJUU0vRG9DcEFnTUJBQUdqCmZ6QjlNQTRHQTFVZER3RUIvd1FFQXdJRm9EQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBUVlJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFkQmdOVkhRNEVGZ1FVamJQUGEzc25heGd6Q3pHV04zenJYOEU3cTJZdwpId1lEVlIwakJCZ3dGb0FVdTllZ0RYZGNxdlVBZjJPNlhJbW0reFQyWHVFd0RRWUpLb1pJaHZjTkFRRUxCUUFECmdnRUJBRENNem9VVFpKU24xVTVkU2pvYk5NdFIrL0NZeEhDdUxNSmUrdGxsRkR0aFV2S3FzSzc0ZFpGN0RMcWwKM2QyZXVIZlRqSlVtbzVhUjQxR21zOUFMcDl0NW5HN2wzTVprcTlQclVuM2EwbkhWdFROT0s0emV5Rno3dlRNSQp3TUlhc1VxZHN3dXZjNlY2Tmw0M0htUU1ncHRjcjYwT1lSRnpweUhOWEZVWW0zaldMKzlQQUlmSDhJL0RLY3krCm1BemNBdVF4ajIzWWMvNHFWT09keWtJdGdQVlJNUC9TZENtNlhNRS9iQlRyblc5N2pjK3Q4N2V0aFVrNm0xclEKUzN5UUcwZ2REYmtvWHJwcG84RUVDeUFtc3ZGbm5kVHRNVjhBdWtFREpCSXBKNU5QazNNbnpnbzJmbkMxVS9kZApuaERXTWxDbEV4OFZidytGV0ZwWGp5dmsyNkU9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBc3NzS2IzUzNUcHlqMUV0Uk45WXRpaEVEeW1FYWd3QTdsTG03a2ZBdklEMGh0TnNDCkRiU1h0bkFSMnlhcmczRDZpOEt4WDFSTC96cTgveFl2SDBQa1ovc3JhNnl5dEpKMlhRT3JTN3lGcXpPRWNncmgKVEh6Zml3VitTU08xUHE3V2p4enhuM29SeEVVNy9HMzdPY1oyNHR3YjdBUTlNRkN4aktLMjdRVHhzMGg0VEd6agpPRjJOZlo1NG9QVmxhLzRZKzRxcGNUTDBpRWRjNE1sc2wvU0s4RFFFZGZVUmpiOWViRjVGVEhZTllFRTM2a1IvCndFUjFwcFJOajBjeXVDdy8yMlUxc2hoTHM3SHphalMrQ2tRQXI5djhJMlhtbEJrd3M4WmRkejNvUmJuR05vUTMKZ3dyWlZJTFlBalZlWUg3Rm9PcFEwRmtRdnJiZk5DRURQdzZBcVFJREFRQUJBb0lCQVFDajJlZHFWVEJZWHJ6VgpKV0Q5SnM3OUpMS3dtV1RPZ1R3WkJFMmRaTndMVTNxOFg2ajJIbmFhdndIZU1RWWxvemc1Tk9lUVVaU0VCclNGCm9UTDJHQ1lPRk9TcC9NNlpKVkJMMWJ6NTMzOHdjam9DdVczWHh1aW1ZeFprdU5DMDdVMjhRZTQ5RklXTHRWZFAKOHdxMDIraS81cS9BRC9KemdMLzEvbmhkcHBaS2thdHFUb0E3eElwVzZiNE5jOEN6VmJCVWtkNkd2VTVPWFBKQQpVUTFOUjhCdmlCRW1ySHJNZ1JnOGdWRWZtaVk3NXhZeldJSkdOY2tIZWVUSHl2V2xZWitFamYxU05Nc2NDd2tPCnRNVmJSektUNklOU2I4ejhXdDZRM0ZoK3VYczYyQnBDSGJYZGdsQUw1SHRUdy9pU29OaVdKVUlQWE1YU1lMOE4KaXVOcVNJVEJBb0dCQU5jMHRzQ0ZKQ1NPbExKTzU2bDVzTkpkUXQwcFRYbTlSaFQ4dE00RWJKWnFueUdrWXJ1RgpGYkhGQWY4ZjlvZVRRb1BTb1h3SWh3VmRCazhZMWtLa3pSZWVqVE92T3huTE4yVWdHeDlocHhKN0pSTlFnYVNBCkxZWUlJd0FnNi9xZnc0RGhZZXQ2dElzTGV0U3o3em9WWnJwT0pVTE13cHFLS3UvaHc4MHB2b01sQW9HQkFOU3YKVTFiWVgwQkYwZ1N4QXlkN2VRK0oxQjdEcVFqSW1xeHh0dldBbWZ5QkMxT29peFZ0dTc1dC83akxZdmxKUHpYVQpYVThNWkI1eG05cXZkTWp0cE42RjNHR3hXNXk4eWRsUlFNeXM0OTIwcUtBTElBQ2ZxT3dLTXpCN3pjQllsL3RUCjZCS1lnZ2dNYXV2TEZJYWtPU2h1YXBhdVhKY2RXU05RTlNQOUZkSTFBb0dCQUl4MVZVbjJIQTdZR0drQVl1Y1UKQzdwaE1FRFVza0pnckpzS0RKL2g5MVY5Slh0NXBROHEzMnYxWDBZNmdGY2dYK3RWMEJ2NkhOWDlUeDdVNFJNQwpLUEhmZzkxVjQwY0VnWlU1RFRyQUs2RStTb1orcHY3TXdlbVc2ZkV0aTVjNkt3bTFFSW4ydmx0NkZLTTdCVXB0CnFXeXprRkkyL2xTTEZWY1hqUW9jMHNFWkFvR0FJVW80RHpYYTR1S0sxdlVsK3o0V1d0cEYrM0xBdUlFOXhKUWcKQVJsYUFPM3A2ZlJOb05NR09lNVp3b0VEUXVXMklTVFdYaE1nY0t0enE2MGU2SHhaL0FLVDFpNittaS9xb0R0WgpteS9Na3QwK0w1N09LWXJVRSs0Y3lRLzN5bzJUYkdGYng5MWJMUXRVaVFmR2RMU3J4YXBTd0xjV0F3a3k5SllQClcweTM1NmtDZ1lBSlkwR2ZaVTFQMFRwZEZpZ2RCaTkwNTFrbjRlSVIvSndMc2QwR3B3UkFUYndwaFhESDEwZjIKR2RBcVJrcWRaYk9DSGhRVTZMcTU3YVNIWVpXbUlzUy9jN0dld21PWjZPZzZyT3FTRlA3Z3JnZC9VYVFpSGh3OQpVN3NDcllKWmxJNmMvbDJPR3c0eDNabnFhRHRiMXpIaXJ3bzYzRFZRdnZmb3I5UTM5OURlUnc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IkVvbUMxMF9hbGkwekNEUzM1QWs1engza1hMT0RxaDZXSUJ3cDJ6eFVXM3cifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJlcnAiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiZXJwLXVzZXIxLXRva2VuLXhzaGNkIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImVycC11c2VyMSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjYyYmJhZDc4LWU4ZjgtNDg3ZC04ZTZlLWJiNjljOWFkOTAzNyIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDplcnA6ZXJwLXVzZXIxIn0.fjZhRpyyVH8huJbRTERiL4KT7Qh-orz0-FWeNFy4LCbEo_6FQ9pb-BsH4IaoJe4qq_L14HB_dslYas8tAPbmAuQUtp6ML1RPwmCkoFy_P-Ny0m054Moy8CC4nWEg8Olii7wApXlv1GaraNWTAZr69MNAH86DH3mVS56iD498eEJ8Ef4rgnHUVBWsJg3eEaFwqNSNQeZi38qVtgtxYup8viftTVuPjcDngu9GGHxCxXJdtcTd1kzYpTTJZGEMhZpT4_1mawF4x8Q7xvBB4UyWB8jy9vnf8SiB1Onf0XptcG2B6ya-Jw12qPzUFW7Dt8zhWKS_UW2MWaDz1kKIxUHj9Q
```

注意:

1. token信息写在kubeconfig文件的最后边
2. token信息那一行前面有4个空格

### 3.9 尝试使用kubeconfig文件登录

![尝试使用kubeconfig登录](./img/尝试使用kubeconfig登录.png)

![使用kubeconfig登录成功](./img/使用kubeconfig登录成功.png)

## PART4. kubernetes网络简介

公有云的K8S服务,不支持calico网络组件.通常是使用flannel.因为公有云有一些底层的协议不支持.

[集群网络系统](https://kubernetes.io/zh/docs/concepts/cluster-administration/networking/)

容器网络的目的:

1. 实现同一个pod中的不同容器通信(同一个Pod中的LNMP容器,通过localhost解决)
2. 实现pod与pod同主机与跨主机的容器通信(微服务)
3. pod和服务之间的通信(nginx通过Service调用tomcat)
4. pod与k8s之外的网络通信

	- 外部到pod(客户端的请求)
	- pod到外部(响应报文)

![CNI插件的三种实现模式](./img/CNI插件的三种实现模式.png)

Overlay用的比较多.因为后期节点扩容比较方便.

- Overlay:Overlay网络下,一个数据报会被封装2次.第1次是在虚拟网卡上封装,第2次是在物理网卡上封装.然后在交换机上进行路由(路由过程中会将源mac地址替换为交换机的mac地址),路由后发送给对端物理机的网卡上.对端物理网卡进行第一次解包,解包后确认目的地址为容器地址,再将数据报发送给容器的虚拟网卡,容器的虚拟网卡进行第2次解包.

	- 这样的设计,其优点在于使得数据报可以在不同的网段之间进行转发.通信靠3层(虚拟网卡->物理网卡->交换机)路由来打通的.不受mac地址的限制.但缺点在于带宽有所损耗,因为隧道需要封装.

- 直接路由:物理机上直接进行路由选址.其优点在于不需要虚拟设备的二次封装,性能会有提升.其缺点在于,不能跨网段.因为这种通信模式是2层(物理网卡->交换机)来打通的.因为跨网段的情况下,交换机中是没有对端的路由信息的.也就是说跨网段的数据报会在交换机上被丢弃.这种通信模式严格要求每个主机(物理机)上都要有容器的目的路由信息.可以在3层交换机上,使用`routeadd`手动加路由的方式解决跨网段的问题.

- Underlay:容器网段和宿主机网段是同一个网段.容器直接桥接到宿主机上.宿主机直接把报文转发给交换机.从交换机的视角上来看,容器的数据报和宿主机的数据报没区别.可以认为就是虚拟机的桥接网卡.其优点在于通信模式简单,不需要做封装.其缺点在于管理很困难.因为每个容器都需要一个IP地址.地址池就需要人去维护.且容易引起广播风暴.

从性能的角度上来看: Underlay > 直接路由 > Overlay

### 4.1 网络通信方式

#### 4.1.1 二层通信

基于目标mac地址通信,不可跨局域网通信,通常是由交换机实现报文转发.

- private mode:private 模式下,同一父接口下的子接口之间彼此隔离,不能通信,从外部也无法访问.也就是说同一个pod内的容器无法通信,因此这个模式很少用.
- vepa(Virtual Ethernet Port Aggregator,虚拟以太网端口聚合器)mode:vepa模式下,子接口之间的通信流量需要导到外部支持 802.1Qbg/VPEA功能的交换机上(可以是物理的或者虚拟的),经由外部交换机转发,再绕回来.这种模式下,即使是同一个pod内的容器间通信,也需要先发送给交换机,再从交换机上发送给对端容器.比较消耗交换机的资源.
- bridge mode:bridge模式下,模拟的是Linux bridge的功能,但比bridge要好的一点是每个接口的MAC地址是已知的,不用学习,所以这种模式下,子接口之间就是直接可以通信的.这种模式比较常用.
- passthru mode(直通模式):passthru模式下,只允许单个子接口连接父接口.1个物理网卡只能有1个子接口,这种模式肯定是不行的.用的更少.
- source mode:这种模式,只接收源mac地址为指定的mac地址的报文.这种模式要求容器只能接收mac地址为指定mac地址的数据报,很少有这种需求,

![各个模式的二层通信示意图](./img/各个模式的二层通信示意图.png)

红线表示不互通,绿线表示互通.

#### 4.1.2 三层通信

基于目标IP通信,也叫做IP交换技术,解决了跨局域网、跨网络通信,通常是由路由器、防火墙、三层交换机等设备实现.

![三层通信示意图](./img/三层通信示意图.png)

Overlay就是这种模式.

![三层通信示意图2](./img/三层通信示意图2.png)

#### 4.1.3 网桥(bridge)

安装完docker之后会默认生成一个docker的网桥设备(docker0),网桥设备通过mac地址转发报文到各个容器,如果容器要访问当前宿主机以外的容器或者网络,则会使用宿主机的路由功能进行源地址转换

![docker0设备通信](./img/docker0设备通信.png)

#### 4.1.4 Vlan

VLAN(Virtual Local Area Network)即虚拟局域网,是将一个物理(交换机)的网络在逻辑上划分成多个广播域的通信技术.VLAN内的主机间可以直接通信,而VLAN网络外的主机需要通过三层网络设备转发才可以通信,因此一个vlan可以将服务器的广播报文限制在一个VLAN内,从而降低单个网络环境中的广播报文.vlan采用12位标识的vlanID,即一个交换机设备最多为2^12=4096个vlan

![VLAN](./img/VLAN.png)

#### 4.1.5 Overlay网络简介

叠加网络或者覆盖网络,在物理网络的基础之上叠加实现新的虚拟网络,即可使网络的中的容器可以相互通信.

![overlay](./img/overlay.png)

##### 4.1.5.1 overlay网络实现方式

VxLAN:VxLAN全称是Visual eXtensible Local Area Network(虚拟扩展本地局域网),主要由Cisco推出,vxlan是一个VLAN的扩展协议,是由IETF定义的NVO3(Network Virtualization over Layer 3)标准技术之一.VXLAN的特点是将L2的以太帧封装到UDP报文(即L2 over L4)中,并在L3网络中传输.即使用MAC in UDP的方法对报文进行重新封装,VxLAN本质上是一种overlay的隧道封装技术.它将L2的以太网帧封装成L4的UDP数据报,然后在L3的网络中传输,效果就像L2的以太网帧在一个广播域中传输一样.实际上L2的以太网帧跨越了L3网络传输,但是却不受L3网络的限制.vxlan采用24位标识vlanID号,因此可以支持2^24=16777216个vlan,其可扩展性比vlan强大的多,可以支持大规模数据中心的网络需求.

![VXLAN数据报格式](./img/VXLAN数据报格式.png)

VTEP(VXLAN Tunnel Endpoint vxlan 隧道端点),VTEP是VXLAN网络的边缘设备.是VXLAN隧道的起点和终点.VXLAN对用户原始数据帧的封装和解封装均在VTEP上进行,用于VXLAN报文的封装和解封装,VTEP与物理网络相连,分配的地址为物理网络IP地址,VXLAN报文中源IP地址为本节点的VTEP地址,VXLAN报文中目的IP地址为对端节点的VTEP地址,一对VTEP地址就对应着一个VXLAN隧道.服务器上的虚拟交换机(隧道flannel.1就是 VTEP),比如一个虚拟机网络中的多个vxlan就需要多个VTEP对不同网络的报文进行封装与解封装.

```
root@k8s-master-1:~# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG    0      0        0 eth0
10.200.76.128   192.168.0.193   255.255.255.192 UG    0      0        0 tunl0
10.200.109.64   192.168.0.191   255.255.255.192 UG    0      0        0 tunl0
10.200.140.64   192.168.0.192   255.255.255.192 UG    0      0        0 tunl0
10.200.168.0    192.168.0.183   255.255.255.192 UG    0      0        0 tunl0
10.200.182.64   192.168.0.182   255.255.255.192 UG    0      0        0 tunl0
10.200.196.0    0.0.0.0         255.255.255.192 U     0      0        0 *
172.16.1.0      0.0.0.0         255.255.255.0   U     0      0        0 eth1
192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

其中Use Iface为tunl0的路由,即为VxLAN的路由.可以看到一般隧道对于容器而言,都是网关(UG).

VNI(VXLAN Network Identifier):VXLAN网络标识VNI类似VLANID,用于区分VXLAN段.不同VXLAN段的虚拟机不能直接二层相互通信,一个VNI表示一个租户,即使多个终端用户属于同一个VNI,也表示一个租户.

![对K8S的请求的完整通信过程](./img/对K8S的请求的完整通信过程.png)

NVGRE:Network Virtualization using Generic Routing Encapsulation,主要支持者是Microsoft.与VXLAN不同的是,NVGRE没有采用标准传输协议(TCP/UDP),而是借助通用路由封装协议(GRE).NVGRE使用GRE头部的低24位作为租户网络标识符(TNI),与VXLAN一样可以支持1777216个vlan

##### 4.1.5.2 overlay网络验证

![overlay网络验证](./img/overlay网络验证.png)

注:此抓包必须使用flannel网络插件才能抓到包,我的K8S集群使用的是calico网络查件,所以用的别人的图.抓包命令为:`tcpdump -i eth0 udp port 8472`

#### 4.1.6 underlay简介

Underlay网络就是传统IT基础设施网络(其实就是物理网络),由交换机和路由器等设备组成,借助以太网协议、路由协议和VLAN协议等驱动.它还是Overlay网络的底层网络,为Overlay网络提供数据通信服务.容器网络中的Underlay网络是指借助驱动程序将宿主机的底层网络接口直接暴露给容器的一种网络构建技术.较为常见的解决方案有MAC VLAN、IP VLAN和直接路由等.

Underlay依赖于宿主机网络进行跨主机通信.

##### 4.1.6.1 bridge与macvlan模式

- Bridge:桥接模式 
- MAC VLAN:支持在同一个以太网接口上虚拟出多个网络接口(子接口),每个虚拟接口都拥有唯一的MAC地址并可配置网卡子接口IP

![underlay网络通信过程](./img/underlay网络通信过程.png)

MAC VLAN模式类似于在服务器上装了个keepalived.

keepalived的VIP(Virtual IP)的mac地址:

```
root@k8s-haproxy-1:~# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.189  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 fe80::20c:29ff:fe9d:bac1  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:9d:ba:c1  txqueuelen 1000  (Ethernet)
        RX packets 661595  bytes 76818721 (76.8 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1065251  bytes 73956037 (73.9 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0:0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.118  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:9d:ba:c1  txqueuelen 1000  (Ethernet)

eth0:1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.119  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:9d:ba:c1  txqueuelen 1000  (Ethernet)

eth0:2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.120  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:9d:ba:c1  txqueuelen 1000  (Ethernet)

eth0:3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.121  netmask 255.255.255.255  broadcast 0.0.0.0
        ether 00:0c:29:9d:ba:c1  txqueuelen 1000  (Ethernet)

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.1.189  netmask 255.255.255.0  broadcast 172.16.1.255
        inet6 fe80::20c:29ff:fe9d:bacb  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:9d:ba:cb  txqueuelen 1000  (Ethernet)
        RX packets 219826  bytes 127480186 (127.4 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 470160  bytes 598219442 (598.2 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 3150  bytes 277920 (277.9 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3150  bytes 277920 (277.9 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

可以看到,VIP的mac地址和宿主机网卡(eth0)的mac地址是一样的.

##### 4.1.6.2 IP VLAN

IP VLAN类似于MAC VLAN,它同样创建新的虚拟网络接口并为每个接口分配唯一的IP地址,不同之处在于,每个虚拟接口将共享使用物理接口的MAC地址,从而不再违反防止MAC欺骗的交换机的安全策略,且不要求在物理接口上启用混杂模式.这种模式更像keepalived,因为所有虚拟接口的MAC地址和物理网卡的MAC地址是相同的.

![MACVLAN模型与IPVLAN模型](./img/MACVLAN模型与IPVLAN模型.png)

注:图中MAC VLAN的容器的mac地址应该是不同的

IP VLAN有L2和L3两种模型,其中IP VLAN L2的工作模式类似于MAC VLAN被用作网桥或交换机,而IP VLAN L3模式中,子接口地址不一样,但是共用宿主机的MAC地址.虽然支持多种网络模型,但MAC VLAN和IP VLAN不能同时在同一物理接口上使用.一般使用MAC VLAN.Linux内核自4.2版本后才支持IP VLAN.

### 4.2 VXLAN通信过程

[VXLAN简介](https://support.huawei.com/enterprise/zh/doc/EDOC1100087027)

[Calico简介](https://www.pianshen.com/article/1890293327/)

![VXLAN通信过程](./img/VXLAN通信过程.png)

#### 4.2.1 vxlan简单通信流程

1. VM A发送L2帧,请求与VM B通信
2. 源宿主机VTEP添加或者封装VXLAN、UDP及IP头部报文
3. 网络层设备将封装后的报文通过标准的报文在三层网络进行转发到目标主机
4. 目标宿主机VTEP删除或者解封装VXLAN、UDP及IP头部
5. 将原始L2帧发送给目标VM

![VXLAN通信流程](./img/VXLAN通信流程.png)

#### 4.2.2 VXLAN通信流程

![VXLAN通信流程2](./img/VXLAN通信流程2.png)

#### 4.2.3 VXLAN报文格式

![VXLAN报文格式](./img/VXLAN报文格式.png)

### 4.3 Docker对网络的支持

```
root@k8s-node-1:~# docker info
Client:
 Debug Mode: false

Server:
 Containers: 40
  Running: 34
  Paused: 0
  Stopped: 6
 Images: 34
 Server Version: 19.03.15
 Storage Driver: overlay2
  Backing Filesystem: extfs
  Supports d_type: true
  Native Overlay Diff: true
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
 Swarm: inactive
 Runtimes: runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: ea765aba0d05254012b0b9e595e995c09186427f
 runc version: dc9208a3303feef5b3839f4323d9beb36df0a9dd
 init version: fec3683
 Security Options:
  apparmor
  seccomp
   Profile: default
 Kernel Version: 4.15.0-112-generic
 Operating System: Ubuntu 18.04.5 LTS
 OSType: linux
 Architecture: x86_64
 CPUs: 4
 Total Memory: 4.814GiB
 Name: k8s-node-1
 ID: OW2W:XBFU:UFWA:4ZHZ:4XLM:QPMX:U63Y:K6YO:OJIF:YJOY:TAPW:TY2S
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Registry: https://index.docker.io/v1/
 Labels:
 Experimental: false
 Insecure Registries:
  192.168.0.184
  127.0.0.0/8
 Registry Mirrors:
  https://docker.mirrors.ustc.edu.cn/
  http://hub-mirror.c.163.com/
 Live Restore Enabled: true
 Product License: Community Engine

WARNING: No swap limit support
```

可以看到,docker对网络的支持有:bridge host ipvlan macvlan null overlay

![docker对网络的支持](./img/docker对网络的支持.png)

对于K8S来讲,K8S是借助其他网络插件来实现对网络通信的支持的.

### 4.4 Docker跨主机通信方案总结

- Bridge:docker0就是默认的桥接网络Docker网络驱动.Docker官方采用的是这种方案,但很难在大规模的集群中使用.因为docker0的IP地址就是172.17.0.1,每台主机上的都一样.那么对于一个172.17.0.1而言,无法区分是哪台主机的172.17.0.1.
- Docker网络驱动:
	- Overlay:基于VXLAN、NVGRE等封装技术实现overlay叠加网络
	- Macvlan:基于Docker宿主机物理网卡的不同子接口实现多个虚拟vlan.一个子接口就是一个虚拟vlan,容器通过宿主机的路由功能和外网保持通信

#### 4.4.1 第三方项目

##### 4.4.1.1 Calico--BGP+IPIP

已被github等公司用于生产环境.

Calico有2种实现方式:

- BGP:官方实现方式(官方建议)
- VXLAN

BGP又分为2种模式:

- IPIP:即Overlay模式
- 直接路由:关了IPIP,就没有Tunnel隧道了

未开启IPIP的状态:

![未开启IPIP的状态](./img/未开启IPIP的状态.png)

开启IPIP的状态:

![开启IPIP的状态](./img/开启IPIP的状态.png)

##### 4.4.1.2 Flannel

Flannel—VXLAN(内核3.12或以上)/UDP,端口为8472

##### 4.4.1.3 OpenvSwitch

OpenvSwitch—VXLAN(内核3.12或以上)/UDP

##### 4.4.1.4 Canal

Canal合并了Calico和Flannel的功能

##### 4.4.1.5 Weave

Weave—VXLAN(内核3.12或以上)和UDP

## PART5. Docker多主机通信之macvlan

macvlan是Linux kernel支持的特性.macvlan类似于宿主机网卡子接口,但相比网卡子接口来说,macvlan接口拥有自己独立的mac地址,因此使用macvlan接口可以允许更多的二层操作.macvlan有四种模式:Private、VEPA、Passthru和bridge

![macvlan示意图](./img/macvlan示意图.png)

### 5.1 Private(私有)模式

在Private模式下,同一个宿主机下的容器不能通信,即使通过交换机再把数据报文转发回来也不行.

![macvlan-private模式](./img/macvlan-private模式.png)

此处使用之前的docker-server节点来演示:

- step1. 在docker-server-1节点上创建一个macvlan网络,其模式为private

```
root@docker-server-1:~# docker network create -d macvlan --subnet=192.168.0.173/24 --gateway=192.168.0.1 -o parent=eth0 -o macvlan_mode=private roach_macvlan_private
698a6eefa8a469c32e72ed0d35b495221443a32400479dab7c8815959106658f
```

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                    DRIVER    SCOPE
236b3191c340   bridge                  bridge    local
fb324000a679   harbor_harbor           bridge    local
7d495f6b47df   host                    host      local
f54100b5188e   none                    null      local
698a6eefa8a4   roach_macvlan_private   macvlan   local
```

```
root@docker-server-1:~# docker inspect roach_macvlan_private
[
    {
        "Name": "roach_macvlan_private",
        "Id": "698a6eefa8a469c32e72ed0d35b495221443a32400479dab7c8815959106658f",
        "Created": "2022-06-08T15:45:30.226455056+08:00",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.173/24",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "macvlan_mode": "private",
            "parent": "eth0"
        },
        "Labels": {}
    }
]
```

- step2. 在docker-server-1节点上创建一个容器,并使用上一步创建的网络

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_private --name=container1 --ip=192.168.0.222 centos:7.9.2009 /bin/bash
[root@f070c5b11bb2 /]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG    0      0        0 eth0
192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

可以看到,此处容器使用的网关,其实就是宿主机的网关.

```
root@docker-server-1:~# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG    0      0        0 eth0
172.16.1.0      0.0.0.0         255.255.255.0   U     0      0        0 eth1
192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

容器内查看IP地址:

```
[root@f070c5b11bb2 /]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.222  netmask 255.255.255.0  broadcast 192.168.0.255
        ether 02:42:c0:a8:00:de  txqueuelen 0  (Ethernet)
        RX packets 5856  bytes 23888293 (22.7 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4166  bytes 298537 (291.5 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 78  bytes 7543 (7.3 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 78  bytes 7543 (7.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

- step3. 在docker-server-2节点上尝试与该容器通信

```
root@docker-server-2:~# ping 192.168.0.222
PING 192.168.0.222 (192.168.0.222) 56(84) bytes of data.
64 bytes from 192.168.0.222: icmp_seq=1 ttl=64 time=1.60 ms
64 bytes from 192.168.0.222: icmp_seq=2 ttl=64 time=0.707 ms
64 bytes from 192.168.0.222: icmp_seq=3 ttl=64 time=0.304 ms
^C
--- 192.168.0.222 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2022ms
rtt min/avg/max/mdev = 0.304/0.870/1.600/0.542 ms
```

- step4. 再在docker-server-1节点上启动一个容器,也使用step1创建的网络

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_private --name=container2 --ip=192.168.0.223 centos:7.9.2009 /bin/bash
```

- step5. 比对container1和container2的网卡信息

container1的网卡信息:

```
[root@f070c5b11bb2 /]# ifconfig -a
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.222  netmask 255.255.255.0  broadcast 192.168.0.255
        ether 02:42:c0:a8:00:de  txqueuelen 0  (Ethernet)
        RX packets 6245  bytes 23913811 (22.8 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4173  bytes 299023 (292.0 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 78  bytes 7543 (7.3 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 78  bytes 7543 (7.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

mac地址为:02:42:c0:a8:00:de

container2的网卡信息:

```
[root@f5409d6baee3 /]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.223  netmask 255.255.255.0  broadcast 192.168.0.255
        ether 02:42:c0:a8:00:df  txqueuelen 0  (Ethernet)
        RX packets 8311  bytes 24025731 (22.9 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 6701  bytes 461289 (450.4 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 76  bytes 6744 (6.5 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 76  bytes 6744 (6.5 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

mac地址为:02:42:c0:a8:00:df

发现二者的网卡mac地址是不同的.

- step2. 从container2尝试和container1通信

```
[root@f5409d6baee3 /]# ping 192.168.0.222
PING 192.168.0.222 (192.168.0.222) 56(84) bytes of data.
^C
--- 192.168.0.222 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2032ms
```

发现是ping不通的.因为网络是private模式.

### 5.2 VEPA模式

虚拟以太端口汇聚器(Virtual Ethernet Port Aggregator,简称 VEPA).在这种模式下,macvlan内的容器不能直接接收在同一个物理网卡的容器的请求数据包,但是可以经过交换机的(端口回流)再转发回来可以实现通信.

![macvlan-vepa模式](./img/macvlan-vepa模式.png)

- step1. 删除private模式的网络

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                    DRIVER    SCOPE
236b3191c340   bridge                  bridge    local
fb324000a679   harbor_harbor           bridge    local
7d495f6b47df   host                    host      local
f54100b5188e   none                    null      local
698a6eefa8a4   roach_macvlan_private   macvlan   local
root@docker-server-1:~# docker network rm roach_macvlan_private
roach_macvlan_private
```

- step2. 在docker-server-1节点上创建一个macvlan网络,其模式为vepa

```
root@docker-server-1:~# docker network create -d macvlan --subnet=192.168.0.173/24 --gateway=192.168.0.1 -o parent=eth0 -o macvlan_mode=vepa roach_macvlan_vepa
bc354e8c88190de54f6bbdfbd28b445520c599fc525e8b45d056495374c16e2e
```

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                 DRIVER    SCOPE
236b3191c340   bridge               bridge    local
fb324000a679   harbor_harbor        bridge    local
7d495f6b47df   host                 host      local
f54100b5188e   none                 null      local
bc354e8c8819   roach_macvlan_vepa   macvlan   local
```

```
root@docker-server-1:~# docker inspect roach_macvlan_vepa
[
    {
        "Name": "roach_macvlan_vepa",
        "Id": "bc354e8c88190de54f6bbdfbd28b445520c599fc525e8b45d056495374c16e2e",
        "Created": "2022-06-08T16:05:02.283805304+08:00",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.173/24",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "macvlan_mode": "vepa",
            "parent": "eth0"
        },
        "Labels": {}
    }
]
```

- step3. 使用该网络创建2个容器

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_vepa --name=container1 --ip=192.168.0.222 centos:7.9.2009 /bin/bash
[root@2f9c2b780a26 /]# 
```

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_vepa --name=container2 --ip=192.168.0.223 centos:7.9.2009 /bin/bash
[root@b99594c4f4bb /]#
```

- step4. 尝试在容器间通信

```
[root@b99594c4f4bb /]# ping 192.168.0.222
PING 192.168.0.222 (192.168.0.222) 56(84) bytes of data.
From 192.168.0.223 icmp_seq=1 Destination Host Unreachable
From 192.168.0.223 icmp_seq=2 Destination Host Unreachable
From 192.168.0.223 icmp_seq=3 Destination Host Unreachable
From 192.168.0.223 icmp_seq=4 Destination Host Unreachable
From 192.168.0.223 icmp_seq=5 Destination Host Unreachable
From 192.168.0.223 icmp_seq=6 Destination Host Unreachable
^C
--- 192.168.0.222 ping statistics ---
7 packets transmitted, 0 received, +6 errors, 100% packet loss, time 6132ms
pipe 3
```

注:此处应该是能通信的,或许是我中间的网关地址配错了.

### 5.3 passthru(直通)模式

Passthru模式下该macvlan只能创建一个容器,当运行一个容器后再创建其他容器则会报错.

- step1. 删除之前的网络

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                 DRIVER    SCOPE
236b3191c340   bridge               bridge    local
fb324000a679   harbor_harbor        bridge    local
7d495f6b47df   host                 host      local
f54100b5188e   none                 null      local
bc354e8c8819   roach_macvlan_vepa   macvlan   local
root@docker-server-1:~# docker network rm roach_macvlan_vepa
roach_macvlan_vepa
```

- step2. 在docker-server-1节点上创建一个macvlan网络,其模式为passthru

```
root@docker-server-1:~# docker network create -d macvlan --subnet=192.168.0.173/24 --gateway=192.168.0.1 -o parent=eth0 -o macvlan_mode=passthru roach_macvlan_passthru
07234356ae3df1623fb1c9eab6b09731806a6490dfe2fb2741dbd52ec4f7fda7
```

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                     DRIVER    SCOPE
236b3191c340   bridge                   bridge    local
fb324000a679   harbor_harbor            bridge    local
7d495f6b47df   host                     host      local
f54100b5188e   none                     null      local
07234356ae3d   roach_macvlan_passthru   macvlan   local
root@docker-server-1:~# docker inspect roach_macvlan_passthru
[
    {
        "Name": "roach_macvlan_passthru",
        "Id": "07234356ae3df1623fb1c9eab6b09731806a6490dfe2fb2741dbd52ec4f7fda7",
        "Created": "2022-06-08T16:15:25.252216607+08:00",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.173/24",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "macvlan_mode": "passthru",
            "parent": "eth0"
        },
        "Labels": {}
    }
]
```

- step3. 使用该网络创建一个容器

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_passthru --name=container1 --ip=192.168.0.222 centos:7.9.2009 /bin/bash
```

- step4. 创建第2个容器时报错

![passthru模式下创建第2个容器报错](./img/passthru模式下创建第2个容器报错.png)

### 5.4 bridge模式

在bridge模式下,使用同一个宿主机网络的macvlan容器可以直接通信

- step1. 删除之前的网络

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                     DRIVER    SCOPE
3c47e2dc9f9f   bridge                   bridge    local
fb324000a679   harbor_harbor            bridge    local
7d495f6b47df   host                     host      local
f54100b5188e   none                     null      local
07234356ae3d   roach_macvlan_passthru   macvlan   local
root@docker-server-1:~# docker network rm roach_macvlan_passthru
roach_macvlan_passthru
```

- step2. 创建一个bridge模式的macvlan网络(2个docker-server节点都创建)

在docker-server-1节点上创建:

```
root@docker-server-1:~# docker network create -d macvlan --subnet=192.168.0.173/24 --gateway=192.168.0.1 -o parent=eth0 -o macvlan_mode=bridge roach_macvlan_bridge
4c05f078566330fe97886205115192af6e5ef3967c83a3239ad7ce1a865dc377
```

```
root@docker-server-1:~# docker network ls
NETWORK ID     NAME                   DRIVER    SCOPE
3c47e2dc9f9f   bridge                 bridge    local
fb324000a679   harbor_harbor          bridge    local
7d495f6b47df   host                   host      local
f54100b5188e   none                   null      local
4c05f0785663   roach_macvlan_bridge   macvlan   local
```

```
root@docker-server-1:~# docker inspect roach_macvlan_bridge
[
    {
        "Name": "roach_macvlan_bridge",
        "Id": "4c05f078566330fe97886205115192af6e5ef3967c83a3239ad7ce1a865dc377",
        "Created": "2022-06-08T16:28:43.495581994+08:00",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.173/24",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "macvlan_mode": "bridge",
            "parent": "eth0"
        },
        "Labels": {}
    }
]
```

在docker-server-2节点上创建:

```
root@docker-server-2:~# docker network create -d macvlan --subnet=192.168.0.173/24 --gateway=192.168.0.1 -o parent=eth0 -o macvlan_mode=bridge roach_macvlan_bridge
316f8db3e56f1c618b9725a91332d1a5c2d7be9fe73d8982865114d0b63b47a7
```

```
root@docker-server-2:~# docker network ls
NETWORK ID          NAME                   DRIVER              SCOPE
0ba8e2f3470a        bridge                 bridge              local
ca1b11c919d2        harbor_harbor          bridge              local
d277d2ab7587        host                   host                local
5a9586dfce56        none                   null                local
316f8db3e56f        roach_macvlan_bridge   macvlan             local
```

```
root@docker-server-2:~# docker inspect roach_macvlan_bridge
[
    {
        "Name": "roach_macvlan_bridge",
        "Id": "316f8db3e56f1c618b9725a91332d1a5c2d7be9fe73d8982865114d0b63b47a7",
        "Created": "2022-06-08T16:30:56.774323838+08:00",
        "Scope": "local",
        "Driver": "macvlan",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.173/24",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "macvlan_mode": "bridge",
            "parent": "eth0"
        },
        "Labels": {}
    }
]
```

- step3. 在docker-server-1上使用该网络创建2个容器,并验证单机通信

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_bridge --name=container1 --ip=192.168.0.222 centos:7.9.2009 /bin/bash
[root@415487fa0c3d /]# 
```

```
root@docker-server-1:~# docker run -it --rm --net=roach_macvlan_bridge --name=container2 --ip=192.168.0.223 centos:7.9.2009 /bin/bash
[root@117a8e2f689d /]# 
```

```
[root@415487fa0c3d /]# ping 192.168.0.223
PING 192.168.0.223 (192.168.0.223) 56(84) bytes of data.
64 bytes from 192.168.0.223: icmp_seq=1 ttl=64 time=0.092 ms
64 bytes from 192.168.0.223: icmp_seq=2 ttl=64 time=0.098 ms
64 bytes from 192.168.0.223: icmp_seq=3 ttl=64 time=0.097 ms
^C
--- 192.168.0.223 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2055ms
rtt min/avg/max/mdev = 0.092/0.095/0.098/0.011 ms
```

```
[root@117a8e2f689d /]# ping 192.168.0.222
PING 192.168.0.222 (192.168.0.222) 56(84) bytes of data.
64 bytes from 192.168.0.222: icmp_seq=1 ttl=64 time=0.035 ms
64 bytes from 192.168.0.222: icmp_seq=2 ttl=64 time=0.095 ms
64 bytes from 192.168.0.222: icmp_seq=3 ttl=64 time=0.096 ms
^C
--- 192.168.0.222 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2035ms
rtt min/avg/max/mdev = 0.035/0.075/0.096/0.029 ms
```

- step4. 在docker-server-2上使用该网络创建一个容器,并验证跨主机通信

```
root@docker-server-2:~# docker run -it --rm --net=roach_macvlan_bridge --name=container3 --ip=192.168.0.224 centos:7.9.2009 /bin/bash
[root@00c90b6873bb /]# ping 192.168.0.223
PING 192.168.0.223 (192.168.0.223) 56(84) bytes of data.
64 bytes from 192.168.0.223: icmp_seq=1 ttl=64 time=0.882 ms
64 bytes from 192.168.0.223: icmp_seq=2 ttl=64 time=0.256 ms
64 bytes from 192.168.0.223: icmp_seq=3 ttl=64 time=0.664 ms
^C
--- 192.168.0.223 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2011ms
rtt min/avg/max/mdev = 0.256/0.600/0.882/0.260 ms
```

这种模式性能最强,因为是通过mac地址通信的.但是会产生大量的广播,因为1个容器产生的数据报会广播给同一个网络内的所有容器.且很消耗IP地址.

### 5.5 同一个服务器配置多个macvlan

#### 5.5.1 将服务器对应的交换机接口设置为trunk模式(如果是access模式)

设置交换机模式为trunk:`switchport mode trunk`

#### 5.5.2 Linux服务器添加网卡子接口

`ifconfig eth0.1 192.168.0.202 netmask 255.255.248.0`

#### 5.5.3 在Linux网卡子接口添加新的macvlan

`docker network create -d macvlan --subnet=192.168.0.173/24 --gateway=192.168.0.1 -o parent=eth0.1 -o macvlan_mode=private roach_macvlan_private`

## PART6. K8S网络通信机制

### 6.1 flannel

[文档](https://docs.openshift.com/container-platform/4.10/welcome/index.html)

由CoreOS开源的针对k8s的⽹络服务,其⽬的为解决k8s集群中各主机上的pod相互通信的问题,其借助于etcd维护⽹络IP地址分配,并为每⼀个node服务器分配⼀个不同的IP地址段.

Flannel⽹络模型(后端)⽬前有三种⽅式实现:

- UDP:早期版本的Flannel使⽤UDP封装完成报⽂的跨越主机转发,其安全性及性能略有不⾜
- VXLAN:Linux内核在在2012年底的v3.7.0之后加⼊了VXLAN协议⽀持,因此新版本的Flannel也由UDP转换为VXLAN.VXLAN本质上是⼀种tunnel(隧道)协议,⽤来基于3层⽹络实现虚拟的2层⽹络,⽬前flannel的⽹络模型已经是基于VXLAN的叠加(覆盖)⽹络.⽬前推荐使⽤vxlan作为其⽹络模型
- Host-gw:也就是Host GateWay.通过在node节点上创建到达各⽬标容器地址的路由表⽽完成报⽂的转发,因此这种⽅式要求各node节点本身必须处于同⼀个局域⽹(⼆层⽹络)中,因此不适⽤于⽹络变动频繁或⽐较⼤型的⽹络环境,但是其性能较好.实际上Host-gw模式就是路由模式.

**注意:网络组件及其模式可以换,但是非常麻烦,且必须重启服务器.因此在安装K8S时,一定选择好网络组件,否则后续修改异常麻烦**

Flannel组件的解释:

- Cni0:⽹桥设备,每创建⼀个pod都会创建⼀对veth pair,其中⼀端是pod中的eth0,另⼀端是Cni0⽹桥中的端⼝(⽹卡).Pod中从⽹卡eth0发出的流量都会发送到Cni0⽹桥设备的端⼝(⽹卡)上,Cni0设备获得的ip地址是该节点分配到的⽹段的第⼀个地址
- Flannel.1:overlay⽹络的设备,⽤来进⾏vxlan报⽂的处理(封包和解包),不同node之间的pod数据流量都从overlay设备以隧道的形式发送到对端

注:由于我的集群使用的是calico,故一下所有操作都是我从别人的集群里直接拿过来的.

Flannel的系统文件及目录:

```
root@k8s-node2:~# find / -name flannel
/run/flannel
/usr/bin/flannel
/var/lib/cni/flannel
```

```
cat /var/run/flannel/subnet.env # 获取flannel当前的地址段
```

#### 6.1.1 flannel pod状态

需要再部署k8s的时候使⽤Flannel作为⽹络插件

```
root@k8s-master1:~# kubectl get pods -n kube-system
NAME READY STATUS RESTARTS AGE
kube-dns-75d7c6cd6f-w46pq 3/3 Running 0 13m
kube-flannel-ds-amd64-5xpbl 1/1 Running 1 22m
kube-flannel-ds-amd64-dddt2 1/1 Running 1 22m
kube-flannel-ds-amd64-jrpjn 1/1 Running 1 22m
kube-flannel-ds-amd64-qzk9f 1/1 Running 1 22m
```

#### 6.1.2 创建测试pod

```
root@k8s-master1:/etc/ansible/manifests/dns/kube-dns# kubectl run net-test1 --
image=alpine --replicas=4 sleep 360000
kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a
future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
deployment.apps/net-test1 created
```

#### 6.1.3 验证pod状态

```
root@k8s-master1:~# kubectl get pod -o wide
NAME                      READY STATUS RESTARTS AGE IP NODE NOMINATED NODE READINESS GATES
net-test1-68898c85b7-2lgl6 1/1 Running 0 16m 172.31.3.9 192.168.7.110 <none> <none>
net-test1-68898c85b7-7xshv 1/1 Running 0 12m 172.31.2.5 192.168.7.111 <none> <none>
net-test1-68898c85b7-cb4s4 1/1 Running 0 16m 172.31.3.6 192.168.7.110 <none> <none>
net-test1-68898c85b7-dctmx 1/1 Running 0 16m 172.31.3.5 192.168.7.110 <none> <none>
```

#### 6.1.4 当前node主机IP地址范围

```
root@k8s-node2:~# cat /run/flannel/subnet.env
FLANNEL_NETWORK=172.31.0.0/16
FLANNEL_SUBNET=172.31.2.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
```

#### 6.1.5 当前node主机cni信息

```
root@k8s-node2:~# cat
/var/lib/cni/flannel/a77f70994d452ea66c06f0cec194d937dacac1b69c07d31b478f844f216e84c7
{"hairpinMode":true,"ipMasq":false,"ipam":{"routes":
[{"dst":"172.31.0.0/16"}],"subnet":"172.31.2.0/24","type":"hostlocal"},"isDefaultGateway":true,"isGateway":true,"mtu":1
450,"name":"cbr0","type":"bridge"}
```

#### 6.1.6 当前node主机路由

```
root@k8s-node2:~# route -n
Kernel IP routing table
Destination Gateway Genmask Flags Metric Ref Use Iface
0.0.0.0 192.168.7.254 0.0.0.0 UG 0 0 0 eth0
172.17.0.0 0.0.0.0 255.255.0.0 U 0 0 0 docker0
172.31.0.0 172.31.0.0 255.255.255.0 UG 0 0 0 flannel.1
172.31.1.0 172.31.1.0 255.255.255.0 UG 0 0 0 flannel.1
172.31.2.0 0.0.0.0 255.255.255.0 U 0 0 0 cni0
172.31.3.0 172.31.3.0 255.255.255.0 UG 0 0 0 flannel.1
192.168.0.0 0.0.0.0 255.255.248.0 U 0 0 0 eth0
```

#### 6.1.7 验证flannel的VXLAN配置

```
kubectl edit configmap kube-flannel-cfg -n kube-system
```

vxlan使⽤UDP端⼝8472发送封装好的报⽂:

```
root@k8s-node1:~# netstat -tuanlp | grep 8472
udp 0 0 0.0.0.0:8472 0.0.0.0:*
```

测试⽹络通信:

```
root@k8s-master1:~# kubectl exec -it net-test1-68898c85b7-2lgl6 sh
/ # ifconfig
eth0 Link encap:Ethernet HWaddr 7A:D3:D5:8B:C1:E8
 inet addr:172.31.3.9 Bcast:0.0.0.0 Mask:255.255.255.0
 UP BROADCAST RUNNING MULTICAST MTU:1450 Metric:1
 RX packets:29 errors:0 dropped:0 overruns:0 frame:0
 TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
 collisions:0 txqueuelen:0
 RX bytes:2102 (2.0 KiB) TX bytes:42 (42.0 B)
/ # ping 172.31.2.5
PING 172.31.2.5 (172.31.2.5): 56 data bytes
64 bytes from 172.31.2.5: seq=0 ttl=62 time=0.768 ms
64 bytes from 172.31.2.5: seq=1 ttl=62 time=0.803 ms
64 bytes from 172.31.2.5: seq=2 ttl=62 time=1.010 ms
^C
--- 172.31.2.5 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.768/0.860/1.010 ms
```

#### 6.1.8 VXLAN Directrouting

Directrouting模式是在同⼀个⼆层⽹络中的node节点启⽤直接路由机制,类似于host-gw模式.但同样的场景不如直接使用host-gw,因此这个模式使用的也不多

##### 6.1.8.1 修改flannel⽀持Directrouting

需要让配置⽂件在node节点重新⽣效

```
root@k8s-master1:/etc/ansible# vim roles/flannel/templates/kube-flannel.yaml.j2
 net-conf.json: |
 {
 "Network": "{{ CLUSTER_CIDR }}",
 "Backend": {
 "Type": "{{ FLANNEL_BACKEND }}",
 "Directrouting": true
 }
```

##### 6.1.8.2 验证修改后的路由表

```
#修改为Directrouting之前的路由表
root@k8s-node2:~# route -n
Kernel IP routing table
Destination Gateway Genmask Flags Metric Ref Use Iface
0.0.0.0 192.168.7.254 0.0.0.0 UG 0 0 0 eth0
172.17.0.0 0.0.0.0 255.255.0.0 U 0 0 0 docker0
172.31.0.0 172.31.0.0 255.255.255.0 UG 0 0 0 flannel.1
172.31.1.0 172.31.1.0 255.255.255.0 UG 0 0 0 flannel.1
172.31.2.0 0.0.0.0 255.255.255.0 U 0 0 0 cni0
172.31.3.0 172.31.3.0 255.255.255.0 UG 0 0 0 flannel.1
192.168.0.0 0.0.0.0 255.255.248.0 U 0 0 0 eth0
```

```
#修改为Directrouting之后的路由表
root@k8s-master1:/etc/ansible# ansible-playbook 06.network.yml
root@k8s-node1:~# reboot
root@k8s-node2:~# reboot
root@k8s-node2:~# route -n
Kernel IP routing table
Destination Gateway Genmask Flags Metric Ref Use Iface
0.0.0.0 192.168.7.254 0.0.0.0 UG 0 0 0 eth0
172.17.0.0 0.0.0.0 255.255.0.0 U 0 0 0 docker0
172.31.0.0 192.168.7.102 255.255.255.0 UG 0 0 0 eth0
172.31.1.0 192.168.7.101 255.255.255.0 UG 0 0 0 eth0
172.31.2.0 0.0.0.0 255.255.255.0 U 0 0 0 cni0
172.31.3.0 192.168.7.110 255.255.255.0 UG 0 0 0 eth0
192.168.0.0 0.0.0.0 255.255.248.0 U 0 0 0 eth0
```

##### 6.1.8.3 验证修改后的路由效果

```
#改之前的路由效果
# ifconfig eth0
eth0 Link encap:Ethernet HWaddr BE:EE:B9:F7:62:47 
 inet addr:172.31.3.4 Bcast:0.0.0.0 Mask:255.255.255.0
 UP BROADCAST RUNNING MULTICAST MTU:1450 Metric:1
 RX packets:48 errors:0 dropped:0 overruns:0 frame:0
 TX packets:35 errors:0 dropped:0 overruns:0 carrier:0
 collisions:0 txqueuelen:0
 RX bytes:3700 (3.6 KiB) TX bytes:2286 (2.2 KiB)
# traceroute 172.31.2.4
traceroute to 172.31.2.4 (172.31.2.4), 30 hops max, 46 byte packets
 1 172.31.3.1 (172.31.3.1) 0.049 ms 0.012 ms 0.007 ms
 2 172.31.2.0 (172.31.2.0) 0.520 ms 0.639 ms 4.061 ms
 3 172.31.2.4 (172.31.2.4) 3.544 ms 0.587 ms 0.464 ms
```

```
#改之后的路由效果
# ifconfig eth0
eth0 Link encap:Ethernet HWaddr 5E:83:2C:DD:66:D3 
 inet addr:172.31.3.2 Bcast:0.0.0.0 Mask:255.255.255.0
 UP BROADCAST RUNNING MULTICAST MTU:1450 Metric:1
 RX packets:37 errors:0 dropped:0 overruns:0 frame:0
 TX packets:18 errors:0 dropped:0 overruns:0 carrier:0
 collisions:0 txqueuelen:0
 RX bytes:2824 (2.7 KiB) TX bytes:1170 (1.1 KiB)
# traceroute 172.31.2.2
traceroute to 172.31.2.2 (172.31.2.2), 30 hops max, 46 byte packets
 1 172.31.3.1 (172.31.3.1) 0.007 ms 0.018 ms 0.010 ms
 2 192.168.7.111 (192.168.7.111) 1.174 ms 0.244 ms 2.292 ms
 3 172.31.2.2 (172.31.2.2) 2.527 ms 0.549 ms 0.456 ms
```

#### 6.1.9 flannel不同node上的pod的通信

Flannel.1是⼀个overlay⽹络的设备,⽤来进⾏vxlan报⽂的处理(封包和解包),不同node之间的pod数据流量都从overlay设备以隧道的形式发送到对端.

![flannel在不同node中的pod的通信](./img/flannel在不同node中的pod的通信.png)

- step1. pod中产⽣数据,根据pod的路由信息,将数据发送到Cni0
- step2. Cni0根据节点的路由表,将数据发送到隧道设备flannel.1
- step3. Flannel.1查看数据包的⽬的ip,从flanneld获得对端隧道设备的必要信息,封装数据包
- step4. Flannel.1将数据包发送到对端设备,对端节点的⽹卡接收到数据包
- step5. 对端节点发现数据包为overlay数据包,解开外层封装,并发送到到本机flannel.1设备
- step6. Flannel.1设备查看数据包,根据路由表匹配,将数据发送给Cni0设备
- step7. Cni0匹配路由表,发送数据给⽹桥上对应的端⼝(pod)

![flannel在不同node中的pod的通信2](./img/flannel在不同node中的pod的通信2.png)

#### 6.1.10 host-gw网络模型

```
# 设置flannel 后端
FLANNEL_BACKEND: "host-gw"
#FLANNEL_BACKEND: "vxlan"
#DIRECT_ROUTING: true
/ # traceroute 10.10.4.6 #跨主机容器
traceroute to 10.10.4.6 (10.10.4.6), 30 hops max, 46 byte packets
 1 10.10.3.1 (10.10.3.1) 0.003 ms 0.004 ms 0.001 ms
 2 172.31.6.210 (172.31.6.210) 1.166 ms 0.495 ms 0.579 ms
 3 10.10.4.6 (10.10.4.6) 0.307 ms 0.335 ms 0.322 ms
/ #
/ # traceroute 172.31.6.207
traceroute to 172.31.6.207 (172.31.6.207), 30 hops max, 46 byte packets
 1 10.10.3.1 (10.10.3.1) 0.003 ms 0.004 ms 0.001 ms
 2 172.31.6.207 (172.31.6.207) 1.290 ms 0.776 ms 2.041 ms
```

### 6.2 Calico

[官网](https://www.tigera.io/project-calico/)

Calico是⼀个纯三层的⽹络解决⽅案,为容器提供多node间的访问通信,calico将每⼀个node节点都当做⼀个路由器(router),各节点通过BGP(Border Gateway Protocol,边界⽹关协议)学习并在node节点⽣成路由规则,从⽽将不同node节点上的pod连接起来进⾏通信.

BGP是⼀个去中⼼化的协议,它通过⾃动学习和维护路由表实现⽹络的可⽤性,但是并不是所有的⽹络都⽀持BGP,另外为了跨⽹络实现更⼤规模的⽹络管理,calico还⽀持IP-in-IP的叠加模型,简称IPIP,IPIP可以实现跨不同⽹段建⽴路由通信,但是会存在安全性问题.其在内核内置,可以通过Calico的配置⽂件设置是否启⽤IPIP,在公司内部如果k8s的node节点没有跨越⽹段建议关闭IPIP.

IPIP是⼀种将各Node的路由之间做⼀个tunnel,再把两个⽹络连接起来的模式.启⽤IPIP模式时,Calico将在各Node上创建⼀个名为"tunl0"的虚拟⽹络接⼝.

BGP模式则直接使⽤物理机作为虚拟路由路(vRouter),不再创建额外的tunnel.

Calico核心组件:

- Felix:calico的agent,运⾏在每⼀台node节点上,其主要是维护路由规则、汇报当前节点状态以确保pod的跨主机通信
- BGP Client:每台node都运⾏,其主要负责监听node节点上由felix⽣成的路由信息,然后通过BGP协议⼴播⾄其他剩余的node节点,从⽽相互学习路由实现pod通信
- Route Reflector:集中式的路由反射器,calico v3.3开始⽀持,当Calico BGP客户端将路由从其FIB(Forward Information dataBase,转发信息库)通告到Route Reflector时,Route Reflector会将这些路由通告给部署集群中的其他节点,Route Reflector专⻔⽤于管理BGP⽹络路由规则,不会产⽣pod数据通信

注:calico默认⼯作模式是BGP的node-to-node mesh,如果要使⽤Route Reflector需要进⾏相关配置.而且Route Reflector模式很少用,因为Route Reflector本身是个单体,不具备高可用的能力.

[Calico各组件结构](https://projectcalico.docs.tigera.io/reference/architecture/overview)

[Calico网络配置](https://projectcalico.docs.tigera.io/networking/configuring)

![calico架构](./img/calico架构.png)

Calico是容器的虚拟网卡直接和内核连接,虚拟网卡的另一侧就是Pod.

```
root@k8s-node-1:~# ifconfig
cali11779054436: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::ecee:eeff:feee:eeee  prefixlen 64  scopeid 0x20<link>
        ether ee:ee:ee:ee:ee:ee  txqueuelen 0  (Ethernet)
        RX packets 3883  bytes 336148 (336.1 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7503  bytes 595598 (595.5 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

cali4aa6b2a4444: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::ecee:eeff:feee:eeee  prefixlen 64  scopeid 0x20<link>
        ether ee:ee:ee:ee:ee:ee  txqueuelen 0  (Ethernet)
        RX packets 5225  bytes 485646 (485.6 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 9908  bytes 787193 (787.1 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

cali7b4b4eb8769: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::ecee:eeff:feee:eeee  prefixlen 64  scopeid 0x20<link>
        ether ee:ee:ee:ee:ee:ee  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5  bytes 446 (446.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

calibddf812340d: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::ecee:eeff:feee:eeee  prefixlen 64  scopeid 0x20<link>
        ether ee:ee:ee:ee:ee:ee  txqueuelen 0  (Ethernet)
        RX packets 2735  bytes 213345 (213.3 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1951  bytes 162677 (162.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

calie719d3d9dc0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::ecee:eeff:feee:eeee  prefixlen 64  scopeid 0x20<link>
        ether ee:ee:ee:ee:ee:ee  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5  bytes 446 (446.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 02:42:85:15:a4:db  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.191  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 fe80::20c:29ff:fe4f:d6cc  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:4f:d6:cc  txqueuelen 1000  (Ethernet)
        RX packets 83446  bytes 21341767 (21.3 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 53299  bytes 6696018 (6.6 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.1.191  netmask 255.255.255.0  broadcast 172.16.1.255
        inet6 fe80::20c:29ff:fe4f:d6d6  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:4f:d6:d6  txqueuelen 1000  (Ethernet)
        RX packets 920  bytes 186929 (186.9 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1266  bytes 191669 (191.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 67034  bytes 16074966 (16.0 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 67034  bytes 16074966 (16.0 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

tunl0: flags=193<UP,RUNNING,NOARP>  mtu 1440
        inet 10.200.109.64  netmask 255.255.255.255
        tunnel   txqueuelen 1000  (IPIP Tunnel)
        RX packets 14942  bytes 979131 (979.1 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7770  bytes 592484 (592.4 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

```
root@k8s-node-1:~# brctl show
bridge name	bridge id		STP enabled	interfaces
docker0		8000.02428515a4db	no
```

#### 6.2.1 部署过程

[部署过程](https://projectcalico.docs.tigera.io/getting-started/kubernetes/)

#### 6.2.2 验证当前路由表

calico 2.x版本默认使⽤etcd v2 API;calico 3.x版本默认使⽤ etcd v3 API

```
root@k8s-node-1:~# calicoctl node status
Calico process is running.

IPv4 BGP status
+---------------+-------------------+-------+----------+-------------+
| PEER ADDRESS  |     PEER TYPE     | STATE |  SINCE   |    INFO     |
+---------------+-------------------+-------+----------+-------------+
| 192.168.0.181 | node-to-node mesh | up    | 02:14:50 | Established |
| 192.168.0.182 | node-to-node mesh | up    | 02:14:50 | Established |
| 192.168.0.183 | node-to-node mesh | up    | 02:14:50 | Established |
| 192.168.0.192 | node-to-node mesh | up    | 02:14:49 | Established |
| 192.168.0.193 | node-to-node mesh | up    | 02:14:49 | Established |
+---------------+-------------------+-------+----------+-------------+

IPv6 BGP status
No IPv6 peers found.
```

#### 6.2.3 查看pod路由走向

##### 6.2.3.1 开启IPIP的通信状态

```
root@k8s-node-1:~# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.0.1     0.0.0.0         UG    0      0        0 eth0
10.200.76.128   192.168.0.193   255.255.255.192 UG    0      0        0 tunl0
10.200.109.64   0.0.0.0         255.255.255.192 U     0      0        0 *
10.200.109.66   0.0.0.0         255.255.255.255 UH    0      0        0 cali4aa6b2a4444
10.200.109.68   0.0.0.0         255.255.255.255 UH    0      0        0 calibddf812340d
10.200.109.70   0.0.0.0         255.255.255.255 UH    0      0        0 calie719d3d9dc0
10.200.109.91   0.0.0.0         255.255.255.255 UH    0      0        0 cali7b4b4eb8769
10.200.109.115  0.0.0.0         255.255.255.255 UH    0      0        0 cali11779054436
10.200.140.64   192.168.0.192   255.255.255.192 UG    0      0        0 tunl0
10.200.168.0    192.168.0.183   255.255.255.192 UG    0      0        0 tunl0
10.200.182.64   192.168.0.182   255.255.255.192 UG    0      0        0 tunl0
10.200.196.0    192.168.0.181   255.255.255.192 UG    0      0        0 tunl0
172.16.1.0      0.0.0.0         255.255.255.0   U     0      0        0 eth1
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

类似于`cali4aa6b2a4444`的路由,是本机内的通信;`tunl0`的路由,是跨主机的通信.

```
root@k8s-master1:~# kubectl exec -it net-test1-68898c85b7-z7rgs sh
/ # traceroute 172.31.58.83
traceroute to 172.31.58.83 (172.31.58.83), 30 hops max, 46 byte packets
 1 192.168.7.111 (192.168.7.111) 0.011 ms 0.010 ms 0.004 ms
 2 172.31.58.64 (172.31.58.64) 0.300 ms 0.505 ms 0.324 ms
 3 172.31.58.83 (172.31.58.83) 0.498 ms 0.619 ms 0.422 ms
/ #
```

##### 6.2.3.2 关闭IPIP的通信状态

需要重新部署K8S环境,故此处用的是别人的笔记

```
当前路由表：
root@k8s-node1:~# route -n
Kernel IP routing table
Destination Gateway Genmask Flags Metric Ref Use Iface
0.0.0.0 192.168.7.254 0.0.0.0 UG 0 0 0 eth0
172.17.0.0 0.0.0.0 255.255.0.0 U 0 0 0 docker0
172.31.13.128 192.168.7.111 255.255.255.192 UG 0 0 0 eth0
172.31.58.64 0.0.0.0 255.255.255.255 UH 0 0 0 cali2fd25f96bb2
172.31.58.64 0.0.0.0 255.255.255.192 U 0 0 0 *
172.31.58.65 0.0.0.0 255.255.255.255 UH 0 0 0 calia6efdd98c77
172.31.185.128 192.168.7.102 255.255.255.255 UGH 0 0 0 eth0
192.168.0.0 0.0.0.0 255.255.248.0 U 0 0 0 eth0
root@k8s-master1:/etc/ansible# kubectl run net-test1 --image=alpine --replicas=4 
sleep 360000 #创建pod进⾏⽹络测试
root@k8s-master1:/etc/ansible# kubectl exec -it net-test1-68898c85b7-qrh7b sh
/ # traceroute 172.31.58.65
traceroute to 172.31.58.65 (172.31.58.65), 30 hops max, 46 byte packets
1 192.168.7.111 (192.168.7.111) 0.009 ms 0.008 ms 0.004 ms
2 192.168.7.110 (192.168.7.110) 0.282 ms 0.344 ms 0.145 ms
3 172.31.58.65 (172.31.58.65) 0.481 ms 0.363 ms 0.197 ms
```