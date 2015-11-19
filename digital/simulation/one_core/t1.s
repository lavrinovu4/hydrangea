# Harvey Mudd College VLSI MIPS Project
# Carl Nygaard
# Spring, 2007
#
# Created: 12/28/06
#
#   Tests immediate instructions, hazards, negative numbers.  


main:   addiu $2, $0, -10       # $2 = -10																					24 02 ff f6
        addiu $3, $0, 10        # $3 = 10																						24 03 00 0a
        addu  $2, $2, $3        # $2 = $2 + $3 = -10 + 10 = 0												00 43 10 21
        addiu $4, $2, 100       # $4 = $2 + 100 = 0 + 10 = 100											24 44 00 64
        addiu $5, $2, -100      # $5 = $2 + -100 = -100															24 45 ff 9c
        slti  $3, $2, -1        # $3 = ($2 < -1) = (0 < -1) = 0											28 43 ff ff
        addu  $2, $2, $3        # $2 = $2 + $3 = 0 + 0 = 0													00 43 10 21
        sltiu $3, $2, 0x7fff    # $3 = (0 < 0x7fff (unsigned)) = 1									2c 43 7f ff
        lui   $4, 0x0070        # $4 = 0x00700000																		3c 04 00 70
        ori   $4, $4, 0xf000    # $4 = 0x00700000 | 0x0000f000 = 0x0070f000					34 84 f0 00
        xori  $4, $4, 0xf0f0    # $4 = 0x0070f000 ^ 0x0000f0f0 = 0x007000f0					38 84 f0 f0
        # although sltiu is unsigned, normal sign extension still occurs on the
        # immediate value
        sltiu $2, $4, -1        # $2 = (0x007000f0 < 0xffffffff) = 1								2c 82 ff ff
        addu  $2, $2, $3        # $2 = $2 + $3 = 1 + 1 = 2													00 43 10 21
				srl  $4, $4, 16 				# $4 = 0x007000f0 >> 16 = 0x00000070 								00 04 24 02
write:  sw   $2, 0x500($4)          # should write 2 to address 0x00000570							ac 82 00 00

        ori  $2, $0, 0x0570
        lw   $3, 0($2)

        sw   $3, 0x504($0)          #save data to addrees 8/4=2

        addi $3, $0, 1
        sw   $3, 0x500($0)          #write to addres 4/4=1 - our data is valid

end:    beq  $0, $0, end        # loop forever

