# MOTOPP – Flask + MySQL + Redis DevOps Project

## Overview
**MOTOPP** is a containerized web application built with **Flask**, **MySQL**, and **Redis**.  
It demonstrates a full **DevOps lifecycle** including Infrastructure as Code (Terraform), Container Orchestration (Kubernetes), and CI/CD Automation (GitHub Actions).

---

## Tech Stack
- **Backend:** Flask (Python 3.9)
- **Database:** MySQL 8
- **Cache:** Redis (Alpine)
- **Infrastructure:** AWS (EC2, VPC, S3) via Terraform
- **Orchestration:** Kubernetes (Minikube) & Docker Compose
- **CI/CD:** GitHub Actions
- **Monitoring:** Prometheus & Grafana

---

## How to Run

### 1. Run via Docker Compose (Local)
This starts the full stack (App + Database + Redis) locally for development and testing.

```bash
touch .env
echo "MYSQL_PASSWORD=root_password_123" >> .env
echo "SECRET_KEY=my_secret_key_123" >> .env
echo "MYSQL_ROOT_PASSWORD=root_123" >> .env
docker compose up --build
```

**Access App:** http://localhost:5000

---


## Infrastructure Setup & Teardown

### 1. Infrastructure Provisioning (Terraform)
Terraform is used to provision AWS infrastructure such as **VPC** and **EC2** instances.

```bash
cd infra
terraform init
terraform plan

terraform apply -auto-approve
```

> **Note:** The `ec2_public_ip` output will be required for the Ansible step.

---

### 2️. Configuration Management (Ansible)
Ansible installs **Docker**, **Minikube**, and **kubectl** on the EC2 instance.
> **Note:** Update inventory.ini with the`ec2_public_ip` as follow.
```
[webservers]
motopp_server ansible_host=<ec2_public_ip> ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

Before running ansible switch to linux terminal (on Windows via WSL).
```bash
cd ansible

ansible-playbook -i inventory.ini playbook.yaml --private-key ~/motopp.pem
```
 .pem file is obtained by creating key pairs in EC2 instance. It should be in the main directory.

> **Note:** Re-run the same command again if kubectl fails in the first try.
---
### 3️. Teardown (Cleanup)
To destroy all AWS resources and avoid billing charges:

```bash
cd infra
terraform destroy -auto-approve
```
> This will destroy both EC2 & S3 instances, to run the pipeline again, change ec2_public_ip again after running terraform apply command in Step 2.
---

## CI/CD Pipeline
The project uses **GitHub Actions** for a fully automated CI/CD pipeline.

To deploy the app on our remote server we clone this github repo on it.

##### 1. SSH into the remote server using command in the same directory as of `.pem` file:
```
ssh -i "motopp-lab-exam.pem" ubuntu@9<ec2_public_ip>
```
##### 2. Clone the repo:
```
git clone https://github.com/mhhassaan/motopp-devops-final-exam.git motopp-final-exam
```
##### 3. CD to motopp directory and apply K8s manifers
```
cd ./motopp-final-exam/motopp
kubectl apply -f k8s/
```
---

If the CI/CD pipeline fails, change SSH_Host with the current `ec2_public_ip` from Step 2 and retry.

## Monitoring
The monitoring stack includes **Prometheus** and **Grafana**.

- **Prometheus:** Collects metrics from the Kubernetes cluster
- **Grafana:** Visualizes metrics such as:
  - CPU usage
  - Memory usage
  - Network I/O

### Downloading Prometheus & Grafana

#####  1. SSH into the server
```
ssh -i "motopp-lab-exam.pem" ubuntu@<ec2_public_ip>
```
Make sure to run this command in the same directory where `.pem` file is located.

#####  2. Install
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install (Minimal Config)
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring \
  --create-namespace \
  --set alertmanager.enabled=false \
  --set nodeExporter.enabled=false \
  --set prometheus.prometheusSpec.resources.requests.cpu=10m \
  --set prometheus.prometheusSpec.resources.requests.memory=50Mi \
  --set grafana.resources.requests.cpu=10m \
  --set grafana.resources.requests.memory=50Mi
```

##### 3. Check status of grafana container.
```
kubectl get pods -n monitoring --watch
```
If status is running, then press `Ctrl+C` and access grafana.
If it is giving ImgPullError, it is most probably due to disk space.

Check the space usage using this command:
```
df -h /
```
Run following commands and check status again.
```
rm -rf ~/.minikube/cache
sudo apt-get clean

kubectl delete pod -n monitoring -l app.kubernetes.io/name=grafana pod
```
### Access Grafana

Before accessing the Grafana dashboard we need to get the password using the following command:
```
kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
user: `admin`
password: `<text from above command>`

```bash

kubectl port-forward svc/monitoring-grafana 8080:80 -n monitoring
```

Then on the local terminal/powershell use this command:
```
ssh -i "motopp-lab-exam.pem" -L 3000:localhost:8080 -nNT ubuntu@<ec2_public_ip>
```

Then open **http://localhost:3000** in your browser.

---


### Final Teardown

To destroy all instances simply run the following command:

```
cd infra
terraform destroy
```