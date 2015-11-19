#byte
addiu $2, $0, 0x90
addiu $3, $0, 0x217

sb $2, 0($3)            # [0x17] = 0x90  (sel=8)
sb $2, 3($3)            # [0x1a] = 0x90  (sel=1)

lb $4, 0($3)            # $4 = 0xfffffff90
lbu $5, 3($3)           # $5 = 0x90

add $6, $5, $4          # $6 = 0x20


#halfword
addiu $2, $0, 0x8072
addiu $3, $0, 0x262

sh $2, 0($3)
sh $2, 2($3)

lh $4, 0($3)
lhu $5, 2($3)

add $7, $5, $4
add $7, $6, $7


#word
addiu $2, $0, 0x0fff
addiu $3, $0, 0x240

sw $2, 0($3)
sw $2, 8($3)

lw $8, 0($3)
lw $9, 8($3)

add $10, $8, $9
add $7, $7, $10

#  and right words
 add $5, $0, $0
 lui $2, 0x1234
 ori $2, $2, 0x5678
 #1/4 and 3/4 word
 addiu $3, $0, 0x210
 jal proc
 #2/4 and 2/4 word
 addiu $3, $3, 1
 jal proc
 #3/4 and 1/4 word
 addiu $3, $3, 1
 jal proc

 #1 word
 addiu $3, $0, 0x210
 swl $2, 3($3)
 lwl $2, 3($3)
 add $5, $5, $2

 #1 word
 add $2, $0, $0
 lui $2, 0x1111
 or 	$2, $2, 0x1111
 swr $2, 0($3)
 lwr $2, 0($3)
 addu $5, $5, $2

 addu $7, $7, $5

sw $7, 0x504($0)
ori $2, $0, 1
sw $2, 0x500($0)

loop:
j loop


proc:
	add $4, $0, $0
	swl $2, 0($3)
	swr $2, 1($3)
	lwl $4, 0($3)
	add $5, $5, $4
	lwr $4, 1($3)
	add $5, $5, $4

	jr $31
