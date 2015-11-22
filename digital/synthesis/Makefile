SIMULATION = simulation
MEMORY = mem/mem.mif
RESULT = output_files

COMP = mips-linux-gnu

all: synthesis gen_netlist

.PRECIOUS: %.mif

../../sw/top/program.elf:
	make -C ../../sw/top

%.elf: ../../sw/top/program.elf
	cp ../../sw/top/program.elf $@

clean: clean_q clean_cc
	make -C ../../sw/top clean

clean_all: clean_q clean_cc_all

##########################################################
#
#SYNTHESIS
#
##########################################################
NAME_PROJECT = $(patsubst %.qsf,%,$(firstword $(wildcard *.qsf)))

ifneq ($(NAME_PROJECT),)
FILES = $(foreach i,$(shell cat $(NAME_PROJECT).qsf | grep VERILOG_FILE),$(if $(suffix $(i)),$(i)))
endif

.PHONY: help all synthesis pgm clean

help:
	echo "synthesis   	- makes synthesis for altera device(need file *.qsf)"
	echo "gen_netlist   - generate netlist(need file *.qsf)"
	echo "all   				- two previous"
	echo "pgm       		- program devices(need file *.qsf)"

gen_netlist: $(SIMULATION)/$(NAME_PROJECT).vo
synthesis: $(RESULT)/$(NAME_PROJECT).sof

pgm:
	sudo jtagd
	quartus_pgm --64bit -c 1 --mode=jtag --operation=p\;$(RESULT)/$(NAME_PROJECT).sof

$(RESULT)/%.sof: $(FILES) $(NAME_PROJECT).qsf $(MEMORY)
	quartus_map $(NAME_PROJECT) --64bit
	quartus_fit $(NAME_PROJECT) --64bit
	quartus_sta $(NAME_PROJECT) --64bit
	quartus_asm $(NAME_PROJECT) --64bit

$(SIMULATION)/%.vo: $(RESULT)/%.sof
	quartus_eda $(NAME_PROJECT) --64bit --simulation --tool=modelsim --format=verilog --output_directory=$(SIMULATION)

##########################################################
#
#CLEAN
#
##########################################################
clean_q:
	rm -rf db incremental_db $(RESULT) $(SIMULATION)
	rm -f *.smsg *.summary *.rpt *.jdi *.pin *.pof *.sof *.mif *.dis *.vo *.sdo *.xrf *.sft \
			*.qws *.done *.stp

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

%.mif: %.dat
	./dat2mif.py $^ > $@

clean_cc:
	rm -f *.elf *.dis

clean_cc_all: clean_cc
	rm -f *.dat

.SILENT:
