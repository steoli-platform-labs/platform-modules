.PHONY: fmt validate

fmt:
	terraform fmt -recursive

validate:
	./scripts/validate.sh
