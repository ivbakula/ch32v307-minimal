PREFIX:=riscv-none-embed-
CFLAGS:=\
	-march=rv32imafc \
	-mabi=ilp32 \
	-msmall-data-limit=8 \
	-msave-restore -Os -fmessage-length=0 -fsigned-char \
	-ffunction-sections -fdata-sections -fno-common \
	-Wunused -Wuninitialized -g

AS_FLAGS:= \
	-x assembler-with-cpp

LDFLAGS:= \
	-T ch32v307.ld -nostartfiles \
	-Xlinker --gc-sections -Wl,-Map,"firmware.map" \
	--specs=nano.specs --specs=nosys.specs \

CC:=$(PREFIX)gcc
OBJDUMP:=$(PREFIX)objdump
OBJCOPY:=$(PREFIX)objcopy

CSRCS:=$(wildcard *.c)
COBJS:=$(patsubst %.c,%.o,$(wildcard *.c))

ASMSRCS=$(wildcard *.S)
ASMOBJS=$(patsubst %.S,%.o,$(wildcard *.S))

ELF:=firmware.elf
HEX:=firmware.hex
BIN:=firmware.bin
LST:=firmware.lst

all: $(ELF) $(HEX) $(BIN) $(LST)

$(ASMOBJS): $(ASMSRCS)
	$(CC) $(CCFLAGS) $(AS_FLAGS) -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"

%.o: %.c
	$(CC) $(CCFLAGS) -std=gnu99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"

$(ELF): $(ASMOBJS) $(COBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(ASMOBJS) $(COBJS)

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(LST): $(ELF)
	$(OBJDUMP) --all-headers --demangle --disassemble -M xw $< > $@
