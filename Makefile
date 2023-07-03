.PHONY: all
all: build

.PHONY: build
build:
	zig build elf2uf2

.PHONY: clean
clean:
	rm -rf build/* zig-*
