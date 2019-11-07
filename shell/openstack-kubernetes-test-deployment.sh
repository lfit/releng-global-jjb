# is the cluster api up?
curl --insecure https://10.30.106.87:6443 | grep Forbidden

# create the deployment
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1

# wait for it to be live
while kubectl get pods | grep bootcamp | awk '{print $3}' != "Running"

# expose the app
kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080

# get the external port assignment
kubectl describe services/kubernetes-bootcamp | grep NodePort: | awk '{print $3}' |  cut -d '/' -f1

# check that the whole thing WORKSPACE
curl http://{ip}:{port} | grep "Hello Kubernetes bootcamp!"
