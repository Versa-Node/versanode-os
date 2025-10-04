
PI_GEN_DIR := pi-gen
CONFIG    := $(abspath config)

.PHONY: setup build clean deepclean

setup:
	@./scripts/fetch_pi_gen.sh

build:
	@./scripts/build.sh

clean:
	@echo "Cleaning $(PI_GEN_DIR)/work and $(PI_GEN_DIR)/deploy..."
	@rm -rf "$(PI_GEN_DIR)/work" "$(PI_GEN_DIR)/deploy"

deepclean: clean
	@echo "Removing $(PI_GEN_DIR)..."
	@rm -rf "$(PI_GEN_DIR)"
