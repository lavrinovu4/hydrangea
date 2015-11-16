# Harvey Mudd College VLSI MIPS Project
# Carl Nygaard
# Spring, 2007
#
# Test 009
#
# Created: 1/8/07
#
#   Overflow exception test.

.set noreorder

main:   j   start                                                                       #0
        j   except                                                                      #1
start:
        addi  $2, $0, 0x001f                                                            #2
        mtc0  $2, $12                                                                   #3
        
        lui   $2, 0x8000        # $2 = 0x80000000 = (largest negative number)           #4
        ori   $2, $2, 0x0000                                                            #5
        addi  $3, $0, 5         #$3 = 0x5                                               #6
                                                               
        sub  $2, $3, $2         #$2 = 0x5 - 0x80000000 (jump to exception code)         #7
        add  $4, $0, $0                                                                 #8
        add  $2, $0, $0                                                                 #9
        sw    $4, 0($2)         # should write 1 to address 0x0                         #0xa

        xor  $2, $2, $2                                                                 #0xb
        lw   $3, 0($2)                                                                  #0xc

        addi $2, $0, 8                                                                  #0xd
        sw   $3, 0($2)          #save data to addrees 8/4=2                             #0xe

        addi $3, $0, 1                                                                  #0xf
        subu  $2, $2, 4                                                                 #0x10
        sw   $3, 0($2)          #write to addres 4/4=1 - our data is valid              #0x11

end:    j end                   # loop forever                                          #0x12

except: mfc0  $4, $13           # get the cause register                                #0x13
        mfc0  $7, $14           # get the exception address                             #0x14
        srl   $4, $4, 1         # align the exception code                              #0x15
        addi  $5, $0, 1         # $5 = 1                                                #0x16
        bne   $4, $5, end       # fail if the exception code is not 1 (stored in $4)    #0x17
        nop                                                                             #0x18
        addi  $7, $7, 0x0008                                                            #0x19

        addi  $5, $0, 0x000f                                                            #0x1a
        mtc0  $5, $12                                                                   #0x1b
    
        jr    $7                                                                        #0x1c
