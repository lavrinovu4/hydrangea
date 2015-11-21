all:
	mips-linux-gnu-gcc -g -Wall -c -mips1 -mno-check-zero-division -EL -fno-builtin  -o program.o program.c
	mips-linux-gnu-gcc -g -Wall -c -mips1 -mno-check-zero-division -EL -fno-builtin  -o cpu_driver.o cpu_driver.c
	mips-linux-gnu-gcc -g -Wall -c -mips1 -mno-check-zero-division -EL -fno-builtin  -o start.o start.s
	mips-linux-gnu-ld --no-check-sections -e 0 -Ttext 0 -Tbss 0x1400 -Tdata 0x1000 -EL start.o cpu_driver.o program.o -o program.elf
	mips-linux-gnu-objdump -S program.elf > program.dis
	cp program.elf ../

clean:
	rm -f *.elf *.o *.dis
