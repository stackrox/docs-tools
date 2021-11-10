.PHONY: all setup bundle
all: bundle

.PHONY: setup
setup:
	yarn install --frozen-lockfile

.PHONY: bundle
bundle:
	env PATH="$(shell yarn bin):$(PATH)" gulp bundle
