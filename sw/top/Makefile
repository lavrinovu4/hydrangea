CCFLAGS = -g -Wall -c -mips1 -mno-check-zero-division -EL $(CFLAGS)

all:
	mips-linux-gnu-gcc $(CCFLAGS) -o program.o program.c
	mips-linux-gnu-gcc $(CCFLAGS) -o cpu_driver.o cpu_driver.c
	mips-linux-gnu-gcc $(CCFLAGS) -o start.o start.s
	mips-linux-gnu-ld --no-check-sections -e 0 -Ttext 0 -Tbss 0x1400 -Tdata 0x1000 -EL start.o cpu_driver.o program.o -o program.elf
	mips-linux-gnu-objdump -S program.elf > program.dis

clean:
	rm -f *.elf *.o *.dis
