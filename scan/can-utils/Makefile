MAKEFLAGS := -k

CFLAGS := -O2 -Wall -Wno-parentheses -Wsign-compare

CPPFLAGS += \
	-I. \
	-Iinclude \
	-DAF_CAN=PF_CAN \
	-DPF_CAN=29 \
	-DSO_RXQ_OVFL=40 \
	-DSCM_TIMESTAMPING_OPT_STATS=54 \
	-DCLOCK_TAI=11 \
	-DSO_TXTIME=61 \
	-DSCM_TXTIME=SO_TXTIME \
	-D_FILE_OFFSET_BITS=64 \
	-D_GNU_SOURCE

PROGRAMS := \
	candump \
	cansend

all: $(PROGRAMS)

clean:
	rm -f $(PROGRAMS) *.o 

candump.o: lib.h
cansend.o: lib.h

candump: candump.o lib.o
cansend: cansend.o lib.o
