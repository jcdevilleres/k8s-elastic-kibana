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

