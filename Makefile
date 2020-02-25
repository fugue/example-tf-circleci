include config.mk

.PHONY: whoami
whoami:
	@$(AWS) sts get-caller-identity --output text
