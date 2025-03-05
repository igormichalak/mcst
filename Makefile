BINARY_NAME = mcst
ARGS ?=

.PHONY: run
run:
	odin run ./src/ -vet -out:$(BINARY_NAME) -- $(ARGS)

.PHONY: test
test:
	odin test ./tests/ -vet -define:ODIN_TEST_THREADS=0 -define:ODIN_TEST_PROGRESS_WIDTH=0
