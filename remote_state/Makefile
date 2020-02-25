include ../config.mk

.PHONY: init
init:
	$(TF) init

.PHONY: deploy
deploy:
	@$(TF) apply -auto-approve

.PHONY: deploy_wait
deploy_wait: ;

.PHONY: teardown
teardown:
	@$(TF) destroy -auto-approve

.PHONY: clean
clean: ;

.PHONY: plan
plan:
	@$(TF) plan

.PHONY: test
test:
	@$(TF) validate
