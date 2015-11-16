COMP = mips-linux-gnu
ALL_LIST_NAME ?= list

all: check t0.dat t1.dat t2.dat t3.dat t4.dat t4.dat t5.dat t6.dat t7.dat sim

clean: clean_v clean_cc
clean_all: clean_v_all clean_cc_all

SOURCES_LIST = ../models/model_data_mem ../models/model_instr_mem ../design/mips .
FILE_LIST = $(foreach i,$(SOURCES_LIST),$(foreach file,$(shell cat $i/Sources.list),$i/$(file)"\n"))

$(ALL_LIST_NAME): $(SOURCES_LIST)
	echo -e $(FILE_LIST) > $@

##########################################################
#
#SIM
#
##########################################################
SIM_FLAGS +=
DEBUG_SIM_FLAGS +=

.PHONY: help sim debug-sim elaborate clean_v clean_v_all

help:
	echo "sim       - simulation(need file list)"
	echo "debug-sim - simulation with gui(need file list)"

debug-sim: $(ALL_LIST_NAME)
	irun -nolog -gui -access +wc -f $^

sim: $(ALL_LIST_NAME)
	irun -nolog -access +wc -f $^

clean_v:
	rm -rf INCA_libs waves.shm .simvision
	rm -f simvision* *.key *.log

clean_v_all: clean
	rm -f *.vcd

##########################################################
#
#Compilation
#
##########################################################
AS = $(COMP)-as
LD = $(COMP)-ld
DIS = $(COMP)-objdump

AFLAGS += -mips1
LFLAGS += -e 0 -Ttext 0 -Tbss 0

.PHONY: clean_cc clean_cc_all

check:
	$(AS) --version >> /dev/null || echo "You should install gcc for mips: https://sourcery.mentor.com/GNUToolchain/release2791" || exit 1

%.o: %.s
	$(AS) $(AFLAGS) -o $@ $<

%.elf: %.o
	$(LD) $(LFLAGS) $< -o $@

%.dis: %.elf
	$(DIS) -d --disassemble-zeroes $< > $@

%.dat: %.dis
	cat $< | grep -v "[0-9a-fA-F]\{9\}" | grep --only-matching "^ *[0-9a-fA-F]\+:[^0-9a-fA-F]*[0-9a-fA-F ]\+" | tr -d " " | grep --only-matching "[0-9a-fA-F]\{8\}" > $@

clean_cc:
	rm -f *.elf *.o *.dis

clean_cc_all: clean_cc
	rm -f *.dat

# .SILENT:
