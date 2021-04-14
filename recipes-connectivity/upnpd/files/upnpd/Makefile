PREFIX ?= $(DESTDIR)/usr
BINDIR ?= $(PREFIX)/bin
WORKDIR ?= ./

all:
	${CC} ${CFLAGS} ${LDFLAGS} ${WORKDIR}upnp_service.c -I=/usr/include/upnp -lupnp -lixml -lpthread -o upnpd
clean:
	rm -f *.o upnpd
