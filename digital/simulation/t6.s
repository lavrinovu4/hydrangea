addiu $2, $0, 31
addiu $3, $0, 4
mult $2, $3
mflo $7                            #31 * 4 = 124
div $2, $3                         #31/4
mfhi $6                             #31 mod 4 = 3

add $7, $7, $6                      #127

multu $2, $3
mtlo $6                             #3
mflo $5                             #3

add $7, $7, $5                      #130

mthi $7
mfhi $7

addi $4, $0, 2
addi $2, $0, -1
mult $2, $4

mflo $4                             #-2
addi $3, $0, -2
bne $4, $3, end

mfhi $4
addi $3, $0, -1
bne $4, $3, end

sw $7, 0x504($0)
end:
ori $7, $0, 1
sw $7, 0x500($0)

loop:
j loop
