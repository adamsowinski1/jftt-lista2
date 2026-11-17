
CC = gcc
CFLAGS = -Wall -Wextra

all: build/lexer

build/lexer: src/lexer.l
	mkdir -p build
	flex -o build/lex.yy.c src/lexer.l
	$(CC) $(CFLAGS) build/lex.yy.c -o build/lexer

clean:
	rm -rf build

.PHONY: all clean
