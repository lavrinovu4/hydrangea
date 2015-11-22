COMP = mips-linux-gnu
ALL_LIST_NAME ?= .srclist

all: compile sim

compile: check test.dat

test.elf: compile/*
	make -C compile

clean: clean_v clean_cc
	rm -f $(ALL_LIST_NAME)
	make -C compile clean

clean_all: clean_v_all clean_cc_all

SOURCES_LIST = . ../../models/memory ../../design/mips ../../design/leds ../../design/wishbone_arbiter

FILE_LIST = $(foreach i,$(SOURCES_LIST),\
								$(foreach file,$(shell cat $i/Sources.list),\
										$(if $(or $(findstring .v,$(file)), $(findstring .sv,$(file))), \
												$i/$(file)"\n",\
												$(file)"\n")))

INC_DIR = $(foreach i,$(SOURCES_LIST),-incdir $i"\n")

$(ALL_LIST_NAME): $(SOURCES_LIST)
	echo -e $(INC_DIR) > $@
	echo -e $(FILE_LIST) >> $@

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
	rm -f simvision* *.key *.log verilog.dump restore*

clean_v_all: clean
	rm -f *.vcd

##########################################################
#
#Compilation
#
##########################################################
DIS = $(COMP)-objdump

.PHONY: clean_cc clean_cc_all

check:
	$(DIS) --version >> /dev/null || echo "You should install gcc for mips: https://sourcery.mentor.com/GNUToolchain/release2791" || exit 1

%.dis: %.elf
	$(DIS) -d --disassemble-zeroes $< > $@

%.dat: %.dis
	cat $< | grep -v "[0-9a-fA-F]\{9\}" | grep --only-matching "^ *[0-9a-fA-F]\+:[^0-9a-fA-F]*[0-9a-fA-F ]\+" | tr -d " " | grep --only-matching "[0-9a-fA-F]\{8\}" > $@

clean_cc:
	rm -f *.elf *.dis

clean_cc_all: clean_cc
	rm -f *.dat

.SILENT:
