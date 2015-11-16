# Harvey Mudd College VLSI MIPS Project
# Carl Nygaard
# Spring, 2007
#
# Test 006
#
# Created: 1/5/07
#
#   Coprocessor 0 status register test.

.set noreorder

main:   addi  $3, $0, -1        # $3 = 0xffffffff
        mtc0  $3, $12           # set SR to all the ones we can
        mfc0  $4, $12           # copy SR to $4
b8:     sw    $0, -3($4)        # should write 0 to 0xf - 3 = 0x1c
                                # (This is the value of the status register when
                                # everything that can be switch is turned on, it
                                # is subject to change though throuout
                                # development.)
        addi $2, $0, 0x1c
        lw   $3, 0($2)

        addi $2, $0, 8
        sw   $3, 0($2)          #save data to addrees 8/4=2

        addi $3, $0, 1
        subu  $2, $2, 4
        sw   $3, 0($2)          #write to addres 4/4=1 - our data is valid

end:    beq   $0, $0, end       # loop forever
        nop
