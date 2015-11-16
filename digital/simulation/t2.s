# mipstest.asm
# David_Harris@hmc.edu 9 November 2005 
#
# Test the MIPS processor.  
#  add, sub, and, or, slt, addi, lw, sw, beq, j
# If successful, it should write the value 7 to address 84

main:   addi $2, $0, 5          # initialize $2 = 5     0       20020005        0
        addi $3, $0, 12         # initialize $3 = 12    4       2003000c        1
        addi $7, $3, -9         # initialize $7 = 3     8       2067fff7        2
        or   $4, $7, $2         # $4 <= 3 or 5 = 7      c       00e22025        3
        and  $5, $3, $4         # $5 <= 12 and 7 = 4    10      00642824        4
        add  $5, $5, $4         # $5 = 4 + 7 = 11       14      00a42820        5
        beq  $5, $7, end        # shouldn't be taken    18      10a7000a        6
        slt  $4, $3, $4         # $4 = 12 < 7 = 0       1c      0064202a        7
        beq  $4, $0, around     # should be taken       20      10800001        8
        addi $5, $0, 0          # shouldn't happen      24      20050000        9
around: slt  $4, $7, $2         # $4 = 3 < 5 = 1        28      00e2202a        a 
        add  $7, $4, $5         # $7 = 1 + 11 = 12      2c      00853820        b
        sub  $7, $7, $2         # $7 = 12 - 5 = 7       30      00e23822        c
        sw   $7, 68($3)         # [80] = 7              34      ac670044        d
        lw   $2, 80($0)         # $2 = [80] = 7         38      8c020050        e
        j    end                # should be taken       3c      08000011        f
        addi $2, $0, 1          # shouldn't happen      40      20020001        10
end:    sw   $2, 84($0)         # write adr 84 = 7      44      ac020054        11

        addi $2, $0, 84
        lw   $3, 0($2)

        addi $2, $0, 8
        sw   $3, 0($2)          #save data to addrees 8/4=2

        addi $3, $0, 1
        subu  $2, $2, 4
        sw   $3, 0($2)          #write to addres 4/4=1 - our data is valid

a_end:  j a_end


