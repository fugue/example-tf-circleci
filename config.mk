-include local-config.mk

AWS_PROFILE ?= default
AWS_ACCESS_KEY_ID ?= $(shell aws configure get aws_access_key_id --profile $(AWS_PROFILE))
AWS_SECRET_ACCESS_KEY ?= $(shell aws configure get aws_secret_access_key --profile $(AWS_PROFILE))

AWS_DEFAULT_REGION ?= us-east-1

AWS=AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) aws

TF = terraform
