all:
	mips-linux-gnu-gcc -g -Wall -c -mips1 -mno-check-zero-division -EL -fno-builtin  -o test.o test.c
	mips-linux-gnu-gcc -g -Wall -c -mips1 -mno-check-zero-division -EL -fno-builtin  -o start.o start.s
	mips-linux-gnu-ld --no-check-sections -e 0 -Ttext 0 -Tbss 0x1400 -Tdata 0x1000 -EL start.o test.o -o test.elf
	cp test.elf ../
