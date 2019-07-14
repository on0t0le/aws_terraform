Before start
$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
$ export AWS_DEFAULT_REGION="eu-central-1"

For manual patching nodeId:

kubectl patch node ip-xxxxx.ap-southeast-2.compute.internal -p '{"spec":{"providerID":"aws:///ap-southeast-2a/i-0xxxxx"}}'

To test autoscaller:
cat <<EoF> test.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-to-scaleout
spec:
  replicas: 1
  template:
    metadata:
      labels:
        service: nginx
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx-to-scaleout
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 500m
            memory: 512Mi
EoF
kubectl apply -f test.yaml

kubectl scale --replicas=10 deployment/nginx-to-scaleout


Init Cluster with config-file:
sudo kubeadm init --config=cluster-config.yaml --ignore-preflight-errors=NumCPU