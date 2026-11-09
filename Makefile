SHIELDS = $(patsubst %.keymap,%,$(notdir $(wildcard config/*.keymap)))

# Workspace west compartilhado (zephyr, zmk, modules). Manifest em $(WORKSPACE)/config/west.yml.
WORKSPACE ?= $(abspath $(CURDIR)/../zmk-workspace)
IMAGE ?= zmkfirmware/zmk-dev-arm:3.5
BOARD ?= xiao_ble//zmk

# O repo vai montado em /repo (somente leitura); o workspace em /workdir.
DOCKER = docker run --rm -u $(shell id -u):$(shell id -g) -e HOME=/tmp \
	-e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0='*' \
	-v $(WORKSPACE):/workdir -v $(CURDIR):/repo:ro -w /workdir $(IMAGE)

.PHONY: all init update clean build copy debug

all: build copy

init:
	@test -f $(WORKSPACE)/config/west.yml || { echo "Workspace ausente: $(WORKSPACE)/config/west.yml"; exit 1; }
	$(DOCKER) bash -c "[ -d .west ] || west init -l config; west update --narrow --fetch-opt=--depth=1"

update:
	$(DOCKER) bash -c "west update --narrow --fetch-opt=--depth=1"

clean:
	rm -rf $(foreach s,$(SHIELDS),$(WORKSPACE)/build/$(s)_left $(WORKSPACE)/build/$(s)_right $(WORKSPACE)/build/$(s)_settings_reset)
	mkdir -p firmware
	rm -rf firmware/*

debug:
	@echo "SHIELDS: $(SHIELDS)"
	@echo "Keymaps found: $(wildcard config/*.keymap)"
	@echo "WORKSPACE: $(WORKSPACE)"

build:
	$(DOCKER) bash -c "\
		west zephyr-export >/dev/null && { \
			west build -s zmk/app -d build/$(SHIELDS)_left -b $(BOARD) -S studio-rpc-usb-uart -- -DZMK_CONFIG=/repo/config -DSHIELD=$(SHIELDS)_left & PID1=\$$! ; \
			west build -s zmk/app -d build/$(SHIELDS)_right -b $(BOARD) -- -DZMK_CONFIG=/repo/config -DSHIELD=$(SHIELDS)_right & PID2=\$$! ; \
			west build -s zmk/app -d build/$(SHIELDS)_settings_reset -b $(BOARD) -- -DSHIELD=settings_reset & PID3=\$$! ; \
			wait \$$PID1 && wait \$$PID2 && wait \$$PID3; \
		}"

copy:
	mkdir -p firmware
	cp $(WORKSPACE)/build/$(SHIELDS)_left/zephyr/zmk.uf2 firmware/$(SHIELDS)_left.uf2
	cp $(WORKSPACE)/build/$(SHIELDS)_right/zephyr/zmk.uf2 firmware/$(SHIELDS)_right.uf2
	cp $(WORKSPACE)/build/$(SHIELDS)_settings_reset/zephyr/zmk.uf2 firmware/settings_reset.uf2
