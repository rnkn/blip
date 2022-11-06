.POSIX:
SRC		= blip.sh
BIN		= blip
PREFIX		= /usr/local

install:
	install -m 755 ${SRC} ${PREFIX}/bin/${BIN}
