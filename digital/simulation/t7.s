j start 									#jmp main program
													#here begins handler
mfc0 $v0, $14 						#get epc
mfc0 $v1, $13 						#get cause register
mfc0 $a0, $12 						#get mask

mtc0 $zero, $13 					#clean causes

addi $v0, $v0, 4 					#correct pc for out of jmp

addiu $t0, $t0, 1 				#update counter of interrupts
add $t2, $t2, $v1

rfe
jr $v0

start:
addiu $t3, $zero, 1
add $t2, $zero, $zero

sw $zero, 0x508($zero)

div $v1, $t2

lui $a1, 0x7fff
ori $a1, $a1, 0xffff
add $a2, $a1, $a1

addi $a3, $zero,0x3
jr $a3

addiu $t1, $zero, 13
loop:
bne $t0, $t1, loop

add $t2, $t0, $t2
sw $t2, 0x504($zero)
sw $t3, 0x500($zero)

loop_for:
	j loop_for

