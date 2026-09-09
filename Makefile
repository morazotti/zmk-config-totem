.PHONY: all clean build copy

all: clean build copy

clean:
	mkdir -p firmware
	rm -rf firmware/*

build:
	docker run --rm -v $(PWD):/workdir -w /workdir zmkfirmware/zmk-dev-arm:3.5 bash -c "\
		west zephyr-export && \
		west build -s zmk/app -d build/totem_left -b xiao_ble -- -DZMK_CONFIG=/workdir/config -DSHIELD=totem_left && \
		west build -s zmk/app -d build/totem_right -b xiao_ble -- -DZMK_CONFIG=/workdir/config -DSHIELD=totem_right && \
		west build -s zmk/app -d build/settings_reset -b xiao_ble -- -DSHIELD=settings_reset"

copy:
	cp build/totem_left/zephyr/zmk.uf2 firmware/totem_left.uf2
	cp build/totem_right/zephyr/zmk.uf2 firmware/totem_right.uf2
	cp build/settings_reset/zephyr/zmk.uf2 firmware/settings_reset.uf2
