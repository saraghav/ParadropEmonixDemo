CC=gcc
SRVBIN=srv
CLIBIN=cli

CFLAGS=-O2 -Wall -DSOCK_TIMEOUT=60

all: srv cli

srv: simplevpn-srv.c
	$(CC) -o $(SRVBIN) $(CFLAGS) simplevpn-srv.c -pthread

cli: simplevpn-cli.c
	$(CC) -o $(CLIBIN) $(CFLAGS) simplevpn-cli.c

install:
	install -D -m755 $(SRVBIN) $(DESTDIR)/bin/$(SRVBIN)
	install -D -m755 $(CLIBIN) $(DESTDIR)/bin/$(CLIBIN)

clean:
	rm -f $(SRVBIN) $(CLIBIN)


