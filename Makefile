SOURCES=$(wildcard tools/*.c)
BIN=$(SOURCES:tools/%.c=build/%)

all: $(BIN)

help:
	@printf "+----------------------------+\n"
	@printf	"|  to build a specific tool: |\n"
	@printf	"|    make [tool]             |\n"
	@printf	"|  to build all tools:       |\n"
	@printf	"|    make                    |\n"
	@printf	"+----------------------------+\n"

options:
	@echo "OBJ			= $(SOURCES)"
	@echo "BIN			= $(BIN)"

build:
	mkdir build

build/%: tools/%.c | build
	gcc -O3 $< -o $@

clean:
	rm -rf build

.PHONY: all
