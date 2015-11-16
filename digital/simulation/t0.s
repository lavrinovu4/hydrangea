# Commands tested:
#   addi, add, beq, sw
#
# Expected Behavior:
#   Fibinnacci Sequence.  


main:   addi $2, $0, 0          # initialize $2 = 0
        addi $3, $0, 1          # initialize $3 = 1
        addi $5, $0, 21         # initialize $5 = 21 (stopping point)
loop:   add  $4, $2, $3         # $4 <= $2 + $3
        add  $2, $3, $0         # $2 <= $3
        add  $3, $4, $0         # $3 <= $4
        beq  $4, $5, write      # when sum is 21, jump to write
        beq  $0, $0, loop       # loop (beq is easier to assemble than jump)
write:  sw   $4, 0x507($2)          # should write 21 @ 0x507 + 13 = 0x514
      
        lw   $3, 0x514($0)
        sw   $3, 0x504($0)          #save data to addrees 8/4=2

        addi $3, $0, 1
        sw   $3, 0x500($0)          #write to addres 4/4=1 - our data is valid

end:    beq  $0, $0, end        # loop forever
