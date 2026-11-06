EE_BIN = nova_dodge.elf
EE_OBJS = main.o
EE_LIBS = -lpad -lpacket -ldma -lgraph -ldraw -lc

all: $(EE_BIN)
	$(EE_STRIP) --strip-all $(EE_BIN)

clean:
	rm -f $(EE_BIN) $(EE_OBJS)

include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal
