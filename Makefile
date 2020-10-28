.POSIX:
PROGRAM		= blip
PREFIX		?= /usr/local

install:
	install -m 755 $(PROGRAM) $(PREFIX)/bin
