# Harvey Mudd College VLSI MIPS Project
# Carl Nygaard
# Spring, 2007
#
# Test 004
#
# Created: 1/1/07
#
#   Tests external interrupt

.set noreorder

main:   j start                                         #0    08 00 00 02
        j ext_int                                       #1    08 00 00 11

start:

    add  $7, $0, $0                                     #2    00 00 38 20
    addi $8, $0, 0x10                                   #3    20 08 00 10
    addi $2, $0, 0x18                                   #4    20 02 00 18
    mtc0 $2, $12      #enable external interrupt        #5    40 82 60 00

end:    j end       # loop forever                      #0x6  10 00 ff ff

ext_int:
    mfc0 $4, $13                                        #0x7  40 04 68 00
    
    addi $5, $0, 8                                      #0x8  20 05 00 08
    bne  $4, $5, int_end                                #0x9  14 85 00 02
    nop                                                 #0xa  00 00 00 00
    addi $7, $7, 1                                      #0xb  20 e7 00 01

     bne $7, $8, int_end                                #0xc  14 e8 ff ff
    nop                                                 #0xd  00 00 00 00

    mtc0 $7, $12                                        #0xe  40 87 60 00

        mfc0 $3, $12                                    #0xf  40 03 60 00
        

        addi $2, $0, 8                                  #0x10 20 02 00 08
        sw   $3, 0($2)   #save data to addrees 8/4=2    #0x11 ac 43 00 00

        addi $3, $0, 1                                  #0x12 20 03 00 01
        subu  $2, $2, 4                                 #0x13 24 42 ff fc
        sw   $3, 0($2)  #write to addres 4/4=1 - our data is valid #0x14 ac 43 00 00

int_end:
    rfe                                                 #0x15 42 00 00 10
                                                        #0x16 00 00 00 00














