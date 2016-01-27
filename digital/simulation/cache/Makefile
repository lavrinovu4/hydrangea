ALL_LIST_NAME ?= .srclist

all: sim

clean: clean_v
	rm -f $(ALL_LIST_NAME)

clean_all: clean_v_all

SOURCES_LIST = .
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

src_gen:
	./handle_verilog.py $(FILE_LIST:"\n"=) cache_ro_int.sv

clean_v:
	rm -rf INCA_libs waves.shm .simvision
	rm -f simvision* *.key *.log verilog.dump restore*

clean_v_all: clean
	rm -f *.vcd

.SILENT:
