LIBDIR = lib
MYMDIR = $(LIBDIR)
TCLSH = ./tclkitsh.exe
WISH = ./tclkit.exe
RST2HTML = C:/Python32/python.exe C:/Python32/Scripts/rst2html.py

# index of loaded Tcl packages
pkgindex:
	echo pkg_mkIndex $(LIBDIR) \*.tcl \*.dll|$(TCLSH)

%.gif: %.png
	convert $< $*.gif

images = f.gif t.gif s.gif i.gif

# convert png to gifs
gifs: $(images)

# mym extension
mym/mym_wrap.c: mym/mym.i mym/mym.h mym/mym.c
	swig -tcl -pkgversion 1.0 mym/mym.i
#swig -tcl -pkgversion 1.0 -namespace mym/mym.i

$(MYMDIR)/mym.dll: mym/mym_wrap.c
	gcc -Ic:/tcl/include -I./ -DUSE_TCL_STUBS -c mym/mym_wrap.c -o mym/mym_wrap.o
	gcc -shared -o $(MYMDIR)/mym.dll mym/mym_wrap.o -L c:/tcl/lib -ltclstub85 -lm

mym: $(MYMDIR)/mym.dll

#mym:
	#critcl3.exe -pkg mym/mym.tcl

all: mym

VFS = build/hmcdemo.vfs

vfs:
	-rm -r build
	mkdir -p $(VFS)/lib/app-hmcdemo

tclkit_rt.exe: vfs tclkit.ico tclkit.inf
	cp tclkit.ico $(VFS)/
	cp tclkit.inf $(VFS)/
	cp tclkit.exe tclkit1.exe
	upx.exe -d tclkit1.exe
	reshacker.exe -delete tclkit1.exe , tclkit2.exe , icongroup,,
	windres.exe -i hmcdemo.rc -o hmcdemo.res -J rc -O res -r
	reshacker.exe -add tclkit2.exe , tclkit3.exe , hmcdemo.res , ,,
	upx.exe tclkit3.exe
	mv tclkit3.exe tclkit_rt.exe
	rm hmcdemo.res tclkit2.exe tclkit1.exe

build: tclkit_rt.exe
	cp $(images) $(VFS)/
	cp main.tcl $(VFS)/
	cp -r 3dm $(VFS)/
	cp -r lib/*.* $(VFS)/lib/app-hmcdemo
	tclkitsh.exe sdx.kit wrap hmcdemo.exe -runtime tclkit_rt.exe -vfs build/hmcdemo.vfs

dist: build
	-rm -r dist
	mkdir dist
	cp -r 3dm dist/
	cp hmcdemo.exe dist/
	cp fabric_eeprom.csv dist/

clean:
	-rm -r build
	-rm -r dist

hlp:
	tclkit.exe gendoc.tcl
	$(RST2HTML) hlp.rst hlp.html

.PHONY: all build dist vfs hlp
