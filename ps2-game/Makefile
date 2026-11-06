EE_BIN = nova_dodge.elf
EE_OBJS = main.o audio.o audsrv_irx.o
EE_LIBS = -laudsrv -lpad -lpacket -ldma -lgraph -ldraw -lc

all: $(EE_BIN)
	$(EE_STRIP) --strip-all $(EE_BIN)

audsrv_irx.c: $(PS2SDK)/iop/irx/audsrv.irx
	$(PS2SDK)/bin/bin2c $< $@ audsrv_irx

clean:
	rm -f $(EE_BIN) $(EE_OBJS) audsrv_irx.c

include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal
