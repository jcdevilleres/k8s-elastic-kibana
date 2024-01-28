minikube start
minikube dashboard
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080
minikube stop
minikube config set memory 9001
minikube delete --all

kubectl create -f https://download.elastic.co/downloads/eck/2.11.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.11.0/operator.yaml
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator

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

kubectl get elasticsearch
kubectl logs -f quickstart-es-default-0
kubectl get service

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

kubectl get kibana
kubectl get service quickstart-kb-http
