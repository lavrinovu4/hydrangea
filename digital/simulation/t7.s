#   Tests wrong instruction

.set noreorder

main:   j start                                         #0    08 00 00 02
        j wr_instr_int                                  #1    08 00 00 11

start:

    add  $7, $0, $0                                     #2    00 00 38 20
    addi $8, $0, 1                                      #3    20 08 00 01
    addi $2, $0, 0x11                                   #4    20 02 00 09
    mtc0 $2, $12     #enable wrong instruction exeption #5    40 82 60 00
    nop                                                 #6    00 00 00 00
    nop                                                 #7    00 00 00 00
    bgez $2, end        #here incorrect command         #8    04 41 00 09
await:
    bne $7, $8, await  #wait untill catch exeption      #9    14 e8 ff ff
    nop                                                 #0xa  00 00 00 00

    mtc0 $7, $12                                        #0xb  40 87 60 00

        mfc0 $3, $12                                    #0xc  40 03 60 00
        

        addi $2, $0, 8                                  #0xd  20 02 00 08
        sw   $3, 0($2)     #save data to addrees 8/4=2  #0xe  ac 43 00 00

        addi $3, $0, 1                                  #0xf  20 03 00 01
        subu  $2, $2, 4                                 #0x10 24 42 ff ff
        sw   $3, 0($2)    #write to addres 4/4=1 - our data is valid  #0x11 ac 43 00 00

end:    beq   $0, $0, end       # loop forever          #0x12 10 00 ff ff
        nop                                             #0x13 00 00 00 00

wr_instr_int:
    mfc0 $4, $13                                        #0x14 40 04 68 00
    
    addi $5, $0, 1                                      #0x15 20 05 00 01
    bne  $4, $5, int_end   #fail if it is not exeption of wrong instruction  #0x16 14 85 00 02
    nop                                                 #0x17 00 00 00 00
    addi $7, $7, 1                                      #0x18 20 e7 00 01

int_end:
    rfe                                                 #0x19 42 00 00 10
                                                        #0x1a 00 00 00 00














