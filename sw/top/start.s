.equ beg_stack1, 0x1800
.equ end_stack1, 0x1c00
.equ beg_stack2, 0x1c00
.equ end_stack2, 0x2000
.equ cpu_regs, 0x2004

__init:
	j __start
	j __testfail

__start:
	
	addiu $ra, $0, __init

	lui $3, %hi(cpu_regs)
	ori $3, $3, %lo(cpu_regs)
	lw $2, 0($3)
	addiu $4, $0, 3
	beq $2, $4, _call_cpu_flow_1
	
	sw $4, 0($3)

	lui $fp, %hi(beg_stack1)
	ori $fp, $fp, %lo(beg_stack1)
	
	lui $sp, %hi(end_stack1)
	ori $sp, $sp, %lo(end_stack1)

	j cpu_flow_0
_call_cpu_flow_1:

	lui $fp, %hi(beg_stack2)
	ori $fp, $fp, %lo(beg_stack2)
	
	lui $sp, %hi(end_stack2)
	ori $sp, $sp, %lo(end_stack2)

	j cpu_flow_1

__testfail:
	mfc0 $2, $13
	sw $2, 0x504($0)
	addiu $2, $0, 0x1
	sw $2, 0x500($0)
_testfail_loop:
	j _testfail_loop
