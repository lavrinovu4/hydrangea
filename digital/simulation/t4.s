sw $0, 0x504($0)
#checking bgez
addi $3, $0, -1
addi $4, $0, 1
bgez $3, l_finish
bgez $4, l_n0
j l_finish

#checking bgezal
l_n0:
bgezal $3, l_finish
bgezal $4, proc

#checking bgtz
bgtz $0, l_finish
bgtz $3, l_finish
bgtz $4, l_n1
j l_finish

#checking blez
l_n1:
blez $4, l_finish
blez $3, l_n2
j l_finish

#checking bltz
l_n2:
bltz $4, l_finish
bltz $0, l_finish
bltz $3, l_n3
j l_finish

#checking bltzal
l_n3:
add $31, $0, $0
bltzal $4, l_finish
add $5, $0, $31
bltzal $5, l_finish
bltzal $3, proc


l_finish:
ori $2, $0, 1
sw $2, 0x500($0)
l_loop:
j l_loop


proc:
	lw $2, 0x504($0)
	add $2, $2, $4
	sw $2, 0x504($0)
	jr $31
	


