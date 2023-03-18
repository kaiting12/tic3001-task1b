# Build docker image
docker build -t task1b-image:mytag ./app/.;

# Set up kind cluster
kind create cluster --name kind-1 --config k8s/kind/cluster-config.yaml;

# Load image into cluster
kind load docker-image task1b-image:mytag --name kind-1;

# Apply deployment manifest
kubectl apply -f k8s/manifests/k8s/backend-deployment.yaml;

# Apply nginx-ingress-controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml;

while [[ "$(kubectl -n ingress-nginx get deploy ingress-nginx-controller | tail -n 1 | awk '{print $2}')" == "0/1" ]]; do
  echo "Deployment not available yet... (Status: $(kubectl -n ingress-nginx get deploy ingress-nginx-controller | tail -n 1 | awk '{print $2}'))"
  sleep 5
done

# Make sure workers are ingress ready
kubectl label node kind-1-worker2 ingress-ready=true;
kubectl label node kind-1-worker3 ingress-ready=true;

# Apply service manifest
kubectl apply -f k8s/manifests/k8s/backend-service.yaml;

# Apply ingress manifest
kubectl apply -f k8s/manifests/k8s/backend-ingress.yaml;