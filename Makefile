SOURCES=$(wildcard tools/*.c)
BIN=$(SOURCES:tools/%.c=%)
DESTDIR=/usr/local
DESTBIN=$(SOURCES:tools/%.c=$(DESTDIR)/bin/%)

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
	@echo "DESTDIR	= $(DESTDIR)"
	@echo "DESTBIN	= $(DESTBIN)"

build:
	mkdir build

%: tools/%.c build
	gcc -O3 $< -o build/$@

clean:
	rm -rf build

install: all
	cp build/* $(DESTDIR)/bin/

uninstall:
	rm $(DESTBIN)
