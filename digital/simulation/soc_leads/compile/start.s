.equ beg_stack, 0x1800
.equ end_stack, 0x2000

__init:
	j __start
	j __testfail

__start:
	lui $fp, %hi(beg_stack)
	ori $fp, $fp, %lo(beg_stack)
	
	lui $sp, %hi(end_stack)
	ori $sp, $sp, %lo(end_stack)

	addiu $ra, $0, __init
	j main


__testfail:
	mfc0 $2, $13
	sw $2, 0x504($0)
	addiu $2, $0, 0x1
	sw $2, 0x500($0)
_testfail_loop:
	j _testfail_loop
