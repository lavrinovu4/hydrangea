ALL_LIST_NAME ?= .srclist

COV_FLAGS = -covscope tb\
						-covdut tb\
						-covfile covfile.ccf \
						-coverage all\
						-covoverwrite \
						-covtest test_of_test\

UVM_FLAGS = +UVM_TESTNAME=default_testcase \
						-uvm \
						-uvmhome /home/lavrinovu4/prog/forStud/ncsim/installer/tools/uvm-1.1 \
						+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
						+UVM_NO_RELNOTES \
					 	+ntb_random_seed=13

all: sim

clean: clean_v
	rm -f $(ALL_LIST_NAME)

clean_all: clean_v_all

SOURCES_LIST = .
FILE_LIST = tb.sv ../../design/mips/cache_ro.v ../../models/memory/sram_cache.v

INC_DIR = $(foreach i,$(SOURCES_LIST),-incdir $i"\n")

$(ALL_LIST_NAME): $(SOURCES_LIST)
	echo -e $(INC_DIR) > $@
	echo -e $(FILE_LIST) >> $@

##########################################################
#
#SIM
#
##########################################################
SIM_FLAGS += $(UVM_FLAGS) $(COV_FLAGS)
DEBUG_SIM_FLAGS += $(UVM_FLAGS) $(COV_FLAGS)

.PHONY: help sim debug-sim elaborate clean_v clean_v_all

help:
	echo "sim       - simulation(need file list)"
	echo "debug-sim - simulation with gui(need file list)"

debug-sim: $(ALL_LIST_NAME)
	irun -nolog -gui -access +wc -f $^ $(DEBUG_SIM_FLAGS) $(if $(wildcard *.tcl),-input $(wildcard *.tcl))

sim: $(ALL_LIST_NAME)
	irun -nolog -access +wc -f $^ $(SIM_FLAGS)

clean_v:
	rm -rf INCA_libs waves.shm .simvision
	rm -f simvision* *.key *.log verilog.dump restore*

clean_v_all: clean
	rm -f *.vcd

.SILENT:
