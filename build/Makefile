VPATH = ../src/:/Users/hth/projects/ladybug/src:/Users/hth/projects/boost41/src:/Users/hth/projects/OS4/src:/Users/hth/projects/modules41

.PHONY: all clean

AFLAGS = -g -l -I../include

%.o: %.s
	aspic18 $(AFLAGS) $<

all: clonix.hex clonix-d.hex nov-64-h.hex nov-64-mldl.hex


clean:
	-rm -f *.o *.lst clonix.hex clonix-images.s \
              clonix-d.hex clonix-d-images.s \
              nov-64-h-images.s nov-64-h.hex \
	      nov-64-mldl-images.s nov-64-mldl.hex \
              nov-64-rambox-images.s nov-64-rambox.hex


# Allow split to be used as a separator, this is an empty target
split:
	touch $?


###########################################################################
#
# Define a Clonix module
#
###########################################################################

clonix-images.s: OS4.mod ladybug.mod boost.mod
	clonix -o$@ --nutstudio-source --module clonix-41 --lock-pages cde $+

ClonixSources = clonix.s clonix-images.s

clonix.hex: $(ClonixSources:%.s=%.o)
	lnpic18 -o $@ ../config/linker-p18f252.scm --list-file linker-clonix.lst --output-format=intel-hex --no-data-init-table-section $^

###########################################################################
#
# Define a Clonix-D module (single page here for trial)
#
###########################################################################

clonix-d-images.s: advantage.mod OS4.mod boost.mod games.mod HP67_fun.mod ext-io.mod ladybug.mod
	clonix -o$@ --nutstudio-source --module clonix-d --lock-pages e $+

ClonixDSources = clonix-d.s clonix-d-images.s

clonix-d.hex: $(ClonixDSources:%.s=%.o)
	lnpic18 -o $@ ../config/linker-p18f2620.scm --list-file linker-clonix-d.lst --output-format=intel-hex --no-data-init-table-section $^


###########################################################################
#
# NoV-64 source file can be compiled in Hepax and MLDL mode, but need
# different #defines, so we give them separate rules.
#
###########################################################################

nov-64-h.o: nov-64.s
	aspic18 $(AFLAGS) -o$@ --list-file nov-64-h.lst -DHEPAX $<

nov-64-mldl.o: nov-64.s
	aspic18 $(AFLAGS) -o$@ --list-file nov-64-mldl.lst -DMLDL $<


###########################################################################
#
# Define a NoV-64 module with Hepax
#
# Here we lock page 'B', Hepax is expected to take 8-A in the allocation,
# and the page order does not matter as the library code hardcode the
# mapping for Hepax. We just need to get any other modules outside this
# range, and the given --lock-pages together with Hepax.mod just happens
# to do just that.A
#
###########################################################################

nov-64-h-images.s: hepax.mod ladybug.mod ext-io.mod OS4.mod boost.mod split hepax.mod OS4.mod ladybug.mod games.mod
	clonix -o$@ --nutstudio-source --module nov-64 --lock-pages b $+

Nov64HSources = nov-64-h-images.s romerase.s ram2rom4.s

nov-64-h.hex: $(Nov64HSources:%.s=%.o) nov-64-h.o
	lnpic18 -o $@ ../config/linker-p18f2620.scm --list-file linker-nov-64-h.lst --output-format=intel-hex --no-data-init-table-section $^


###########################################################################
#
# Define a NoV-64 module as MLDL
#
###########################################################################

nov-64-mldl-images.s: ladybug.mod ext-io.mod OS4.mod boost.mod split ladybug.mod HP67_fun.mod games.mod advantage.mod
	clonix -o$@ --nutstudio-source --module nov-64 --start-page=7 --lock-pages 89ab $+

Nov64MLDLSources = nov-64-mldl-images.s romerase.s ram2rom4.s

nov-64-mldl.hex: $(Nov64MLDLSources:%.s=%.o) nov-64-mldl.o
	lnpic18 -o $@ ../config/linker-p18f2620.scm --list-file linker-nov-64-mldl.lst --output-format=intel-hex --no-data-init-table-section $^


###########################################################################
#
# Define a NoV-64 module as a RAMBOX / 41CY
#
# Untested. Also need an operating system to go into page 8.
#
###########################################################################

nov-64-rambox-images.s:
	clonix -o$@ --nutstudio-source --module nov-64  $+

Nov64RAMBOXSources = nov-64cy.s nov-64-rambox-images.s

nov-64-rambox.hex: $(Nov64RAMBOXSources:%.s=%.o)
	lnpic18 -o $@ ../config/linker-p18f2620.scm --list-file linker-nov-64-rambox.lst --output-format=intel-hex --no-data-init-table-section $^
