USER := $(shell id -u)
CURRENT_DIR := $(shell pwd)
TERRAFORM_IMAGE := hashicorp/terraform:1.9
TERRAFORM_DOCS_IMAGE := quay.io/terraform-docs/terraform-docs:latest

run:
	docker run --rm -it -u $(USER) -v $(CURRENT_DIR):/src -w /src $(IMAGE) $(COMMAND)

git-config:
	git config --local --add core.hooksPath .githooks

td-readme:
	$(MAKE) run IMAGE=$(TERRAFORM_DOCS_IMAGE) COMMAND="."

tf-fmt:
	$(MAKE) run IMAGE=$(TERRAFORM_IMAGE) COMMAND="fmt -recursive"

tf-init:
	$(MAKE) run IMAGE=$(TERRAFORM_IMAGE) COMMAND="init -backend=false"

tf-validate: tf-init
	$(MAKE) run IMAGE=$(TERRAFORM_IMAGE) COMMAND="validate -no-color"

tf-test:
	$(MAKE) run IMAGE=$(TERRAFORM_IMAGE) COMMAND="test"

pre-commit: tf-fmt td-readme tf-validate tf-test

install-vscode-extensions:
	code --install-extension EditorConfig.EditorConfig --force \
		--install-extension hashicorp.terraform --force \
		--install-extension github.copilot --force \
		--install-extension github.copilot-chat --force \
		--install-extension redhat.vscode-yaml --force \
		--install-extension bierner.github-markdown-preview --force \
		--install-extension carlos-algms.make-task-provider --force

init: git-config

init-vscode: init install-vscode-extensions
