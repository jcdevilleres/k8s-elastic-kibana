# k8s-elastic-kibana
Short guide on deploying elastic and kibana within a k8s cluster locally for testing.

# Local Deployment of Elasticsearch and Kibana on Minikube

## What is Kubernetes?

[Kubernetes](https://kubernetes.io/) is an orchestration platform facilitating Docker container deployment, providing scalability, and automating containerized application management.

For local Kubernetes practice, [Minikube](https://minikube.sigs.k8s.io/docs/start/) is an easy-to-configure instance. It includes a local dashboard and `kubectl` functionality.

## Installing Minikube Locally

Install Minikube based on your OS by following this [link](https://minikube.sigs.k8s.io/docs/start/).

### Commands:

- Start your cluster:
  ```bash
  minikube start
  ```

- Initiate the Minikube dashboard:
  ```bash
  minikube dashboard
  ```

- Create a sample deployment:
  ```bash
  kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
  kubectl expose deployment hello-minikube --type=NodePort --port=8080
  ```

- Manage your cluster:
  - Halt the cluster:
    ```bash
    minikube stop
    ```
  - Configure memory:
    ```bash
    minikube config set memory 9001
    ```

- Delete Minikube clusters:
  ```bash
  minikube delete --all
  ```

---

## Install ElasticSearch on Local Minikube

First, install the Elastic Operator:

```bash
kubectl create -f https://download.elastic.co/downloads/eck/2.11.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.11.0/operator.yaml
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

### Install ElasticSearch:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.12.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF
```

OR

```cmd
kubectl apply -f elastic-search.yaml
```

To delete the elastic-search instance 

```cmd
kubectl delete -f elastic-search.yaml
```

Monitor cluster:

```bash
kubectl get elasticsearch
kubectl logs -f quickstart-es-default-0
```

Access Elastic via HTTP:

```bash
kubectl get service
```

---

## Install Kibana on Local Minikube

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.12.0
  count: 1
  elasticsearchRef:
    name: quickstart
EOF
```

OR

```cmd
kubectl apply -f kibana.yaml
```

To delete the kibana instance 

```cmd
kubectl delete -f kibana.yaml
```

Check instance deployment:

```bash
kubectl get kibana
kubectl get service quickstart-kb-http
```

Access Kibana using Elastic credentials.

**Note:**
- Ensure `spec.elasticsearchRef` is identical for both Kibana and ES.
- Minimum memory for ES is 2GB; CPU ideally 1 (configurable based on requirements).

## Install Logstash on Local Minikube

```bash
cat <<EOF | kubectl apply -f -
apiVersion: logstash.k8s.elastic.co/v1alpha1
kind: Logstash
metadata:
  name: quickstart
spec:
  count: 1
  elasticsearchRefs:
    - name: quickstart
      clusterName: qs
  version: 8.12.1
  pipelines:
    - pipeline.id: main
      config.string: |
        input {
          beats {
            port => 5044
          }
        }
        output {
          elasticsearch {
            hosts => [ "${QS_ES_HOSTS}" ]
            user => "${QS_ES_USER}"
            password => "${QS_ES_PASSWORD}"
            ssl_certificate_authorities => "${QS_ES_SSL_CERTIFICATE_AUTHORITY}"
          }
        }
  services:
    - name: beats
      service:
        spec:
          type: NodePort
          ports:
            - port: 5044
              name: "filebeat"
              protocol: TCP
              targetPort: 5044
EOF
```

```bash
kubectl get logstash
```

You can now view the logs using Kibana

## Troubleshooting

### Issue: Cannot connect to pod resources

**Solution:** Troubleshoot connectivity by logging into the pods and checking network connectivity. The suggested approach is to use the Kubernetes DNS service to resolve names to addresses. This way, changes in the IP address won't affect your service.

```bash
kubectl exec -it logstash-ls-0 -n elasticsearch -- /bin/bash
curl -k https://elastic:9200/
curl -k https://10.0.254.21:9200
```
```bash
kubectl get service

NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)          AGE
elastic-es-data            ClusterIP      None           <none>           9200/TCP         35m
elastic-es-http            LoadBalancer   10.0.197.22    X.X.X.X          9200:31316/TCP   35m
elastic-es-internal-http   ClusterIP      10.0.122.148   <none>           9200/TCP         35m
elastic-es-masters         ClusterIP      None           <none>           9200/TCP         35m
elastic-es-transport       ClusterIP      None           <none>           9300/TCP         35m
```

Use hostname "elastic-es-http"

```yaml
output {
  elasticsearch {
    hosts => [ "https://elastic-es-http:9200" ]
    user => "elastic"
    password => "yourpasswordhere"
    ssl_verification_mode => "none"
  }
}
```

Disable SSL verification mode by setting 'ssl_verification_mode' to none (for TESTING only)

### Issue: Pods keep restarting

**Solution:** Check the resource consumption of pods and adjust accordingly. Bear in mind the minimum requirements per service.

```bash
kubectl top pods -n <namespace>
```

```bash
kubectl describe nodes -n <namespace>
```

Minimum resource configuration to run Logstash in a development environment

```yaml
resources:
  requests:
    memory: 0.5Gi
    cpu: 0.1
  limits:
    memory: 1Gi
    cpu: 0.2
```

### Issue: Elasticsearch keeps changing passwords upon redeployment.

**Solution:** Create the Elasticsearch password inside the Kubernetes secret vault before creating the instance.

```bash
kubectl create secret generic -n <namespace> <elastic-name>-es-elastic-user --from-literal=elastic=yourpasswordhere
```
****
