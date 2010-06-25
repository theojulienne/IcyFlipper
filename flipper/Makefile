all: build

clean:
	dsss distclean

build:
	dsss build

install:
	cp flipper $(DESTDIR)/usr/bin/
	mkdir -p $(DESTDIR)/usr/share/applications
	cp flipper.desktop $(DESTDIR)/usr/share/applications/

deb:
	dpkg-buildpackage -rfakeroot
