.PHONY: create_cluster install

all: create_cluster install install_cli login

create_cluster:
	terraform apply
	gcloud config set project brodul-argoci
	gcloud container clusters get-credentials my-gke-cluster --region us-central1 --project brodul-argoci

install:
	kubectl create namespace argocd
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
	sleep 20

install_cli:
	wget https://github.com/argoproj/argo-cd/releases/download/v2.1.3/argocd-linux-amd64
	mv ./argocd-linux-amd64 ./argocd
	chmod u+x ./argocd

login:
	gcloud config set project brodul-argoci
	./argocd login $(shell gcloud compute forwarding-rules list | grep IP_ADDRESS | cut -d ' ' -f 2) --username admin --password $(shell kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d )

delete:
	rm ./argocd
	rm -rf ~/.argocd ~/.kube
	terraform destroy