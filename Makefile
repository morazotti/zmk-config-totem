SHIELDS = $(patsubst %.keymap,%,$(notdir $(wildcard config/*.keymap)))

.PHONY: all update clean build copy debug

all: clean build copy 

init:
	docker run --rm -v $(PWD):/workdir -w /workdir zmkfirmware/zmk-dev-arm:3.5 bash -c "west init -l config"

update:
	docker run --rm -v $(PWD):/workdir -w /workdir zmkfirmware/zmk-dev-arm:3.5 bash -c "west update"

clean:
	docker run --rm -v $(PWD):/workdir -w /workdir zmkfirmware/zmk-dev-arm:3.5 bash -c "\
		rm -rf build/*"
	mkdir -p firmware
	rm -rf firmware/*

debug:
	@echo "SHIELDS: $(SHIELDS)"
	@echo "Keymaps found: $(wildcard config/*.keymap)"

build:
	docker run --rm -v $(PWD):/workdir -w /workdir zmkfirmware/zmk-dev-arm:3.5 bash -c "\
		west zephyr-export && \
		west build -s zmk/app -d build/$(SHIELDS)_left -b xiao_ble//zmk -S studio-rpc-usb-uart -- -DZMK_CONFIG=/workdir/config -DSHIELD=$(SHIELDS)_left && \
		west build -s zmk/app -d build/$(SHIELDS)_right -b xiao_ble//zmk -- -DZMK_CONFIG=/workdir/config -DSHIELD=$(SHIELDS)_right && \
		west build -s zmk/app -d build/settings_reset -b xiao_ble//zmk -- -DSHIELD=settings_reset"

copy:
	cp build/$(SHIELDS)_left/zephyr/zmk.uf2 firmware/$(SHIELDS)_left.uf2
	cp build/$(SHIELDS)_right/zephyr/zmk.uf2 firmware/$(SHIELDS)_right.uf2
	cp build/settings_reset/zephyr/zmk.uf2 firmware/settings_reset.uf2
