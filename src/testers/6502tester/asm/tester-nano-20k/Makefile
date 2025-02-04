
BUILD=../build/tester-nano-20k


X:=$(shell mkdir -p $(BUILD))

TARGETS=mos.mi

TARGETS_B=$(addprefix $(BUILD)/, $(TARGETS))


all:	$(TARGETS_B)

$(BUILD)/%.mi:	$(BUILD)/%.bin
	cat $< | hexdump -v -e '/1 "%02x\n"' >$@

$(BUILD)/%.bin:	$(BUILD)/%.o %.lnk.cfg
	ld65 -C $(basename $(notdir $@)).lnk.cfg -o $@ $<

$(BUILD)/%.o: %.asm
	ca65 -l $(basename $@).lst -o $@ $<