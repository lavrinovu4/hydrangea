# Harvey Mudd College VLSI MIPS Project
# Carl Nygaard
# Spring, 2007
#
# Test 004
#
# Created: 1/1/07
#
#   Tests shift operations.

main:   addiu $2, $0, 0x7f      # $2 = 0x7f
        srl   $3, $2, 5         # $3 = 0x7f >> 5 = 0x03
        sllv  $2, $2, $3        # $2 = 0x7f << 3 = 0x3f8
        sll   $4, $2, 22        # $4 = 0x3f8 << 22 = 0xffc00000
        sra   $4, $4, 22        # $4 = 0xffc00000 >>> 22 = 0xffffffff
        lui   $5, 0x8000        # $5 = 0x8000000
        xor   $4, $4, $5        # $4 = 0xffffffff ^ 0x80000000 = 0x7fffffff
        ori   $5, $0, 5         # $5 = 5
        srav  $4, $4, $5        # $4 = 0x7fffffff >> 5 = 0x03ffffff
				sll 	$3, $3, 3 				# $3 = 0x3 << 3 = 0x18
        sllv  $4, $4, $3        # $4 = 0x03ffffff << 24 = 0xff000000
        ori   $3, $0, 22        # $3 = 0x016
        srlv  $4, $4, $3        # $4 = 0xff000000 >> 22 = 0x000003fc
        sw    $2, 0x200($4)         # should write 0x3f8 to address 0x000005fc

        ori  $2, $0, 0x05fc
        lw   $3, 0($2)
				
        sw   $3, 0x504($0)          #save data to addrees 8/4=2
        addi $3, $0, 1
        sw   $3, 0x500($0)          #write to addres 4/4=1 - our data is valid

end:    beq   $0, $0, end       # loop forever
