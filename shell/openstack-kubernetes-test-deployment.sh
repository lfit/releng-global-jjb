# get the IP of a master
master_ip=$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" -c master_addresses -f value | tr -d "[]'")

# is the cluster api up?
curl --insecure https://"$master_ip":6443 | grep Forbidden

# create the deployment
ssh fedora@"$master_ip" "kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1"

# wait for it to be live
while kubectl get pods | grep bootcamp | awk '{print $3}' != "Running"

# expose the app
ssh fedora@"$master_ip" "kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080"

# get the external port assignment
ssh fedora@"$master_ip" "kubectl describe services/kubernetes-bootcamp | grep NodePort: | awk '{print $3}' |  cut -d '/' -f1"

# check that the whole thing WORKSPACE
curl http://"$master_ip":"$service_port" | grep "Hello Kubernetes bootcamp!"
