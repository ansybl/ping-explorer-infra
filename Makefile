IMAGE_TAG=latest
EXPLORER_VERSION=f3de156546479923b8cb0afa9bafd438b6125ad1
EXPLORER_ARCHIVE=$(EXPLORER_VERSION).tar.gz
EXPLORER_REMOTE_ARCHIVE=https://github.com/ping-pub/explorer/archive/$(EXPLORER_ARCHIVE)
EXPLORER_DIRECTORY=explorer-$(EXPLORER_VERSION)
EXPLORER_DIST=$(EXPLORER_DIRECTORY)/dist
EXPLORER_NODE_MODULES=$(EXPLORER_DIRECTORY)/node_modules
PROJECT=dfpl-playground
REGISTRY=gcr.io/$(PROJECT)
WORKSPACE?=dev
IMAGE_NAME=ping-explorer-$(WORKSPACE)
DOCKER_IMAGE=$(REGISTRY)/$(IMAGE_NAME)
ifndef CI
DOCKER_IT=-it
endif


$(EXPLORER_ARCHIVE):
	wget $(EXPLORER_REMOTE_ARCHIVE)

explorer/download: $(EXPLORER_ARCHIVE)

$(EXPLORER_DIRECTORY): explorer/download
	tar -xvf $(EXPLORER_ARCHIVE)

explorer/extract: $(EXPLORER_DIRECTORY)

$(EXPLORER_NODE_MODULES):
	cd $(EXPLORER_DIRECTORY) && yarn install

explorer/install: $(EXPLORER_NODE_MODULES)

$(EXPLORER_DIST): $(EXPLORER_NODE_MODULES)
	cd $(EXPLORER_DIRECTORY) && yarn build

explorer/build: $(EXPLORER_DIST)

explorer/run: explorer/install
	cd $(EXPLORER_DIRECTORY) && yarn serve

docker/build:
	cd $(EXPLORER_DIRECTORY) && docker build --tag=$(DOCKER_IMAGE):$(IMAGE_TAG) .

docker/login:
	gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

docker/push:
	docker push $(DOCKER_IMAGE):$(IMAGE_TAG)

docker/run:
	docker run $(DOCKER_IT) --publish 8080:80 --rm $(DOCKER_IMAGE)

docker/run/sh:
	docker run $(DOCKER_IT) --entrypoint /bin/sh --rm $(DOCKER_IMAGE)

devops/terraform/select/%:
	terraform -chdir=terraform workspace select $* || terraform -chdir=terraform workspace new $*

devops/terraform/fmt:
	terraform -chdir=terraform fmt

devops/terraform/init:
	terraform -chdir=terraform init -reconfigure

devops/terraform/plan: devops/terraform/select/$(WORKSPACE)
	terraform -chdir=terraform plan

devops/terraform/apply: devops/terraform/select/$(WORKSPACE)
	terraform -chdir=terraform apply -auto-approve

devops/terraform/redeploy: devops/terraform/select/$(WORKSPACE)
	terraform -chdir=terraform destroy -target=google_cloud_run_service.default -auto-approve
	make devops/terraform/apply

devops/terraform/destroy/all: devops/terraform/select/$(WORKSPACE)
	terraform -chdir=terraform destroy

devops/terraform/output: devops/terraform/select/$(WORKSPACE)
	terraform -chdir=terraform output

devops/terraform/output/load_balancer_ip: devops/terraform/select/$(WORKSPACE)
	terraform -chdir=terraform output load_balancer_ip
