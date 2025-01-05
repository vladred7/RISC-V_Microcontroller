lw    s0,         0x78(zero)  #s0 = 175
lw    s1,         0x7C(zero)  #s1 = 255
lw    t1,         0x84(zero)  #t1 = 1
lw    t0,         0x80(zero)  #t0 = 2
addi  t2,   t0,   0x05        #t2 = t0 + 5 = 7
addi  t2,   t0,   0x05        #t2 = t0 + 5 = 7
sw    t0,         0xA0(zero)  #mem(40) = t0 = 2
sw    t1,         0xA4(zero)  #mem(41) = t1 = 1
sw    t2,         0xA8(zero)  #mem(42) = t2 = 7
add   s0,   t0,   t1          #s0 = t0 + t1 = 3
add   s1,   t0,   t2          #s1 = t0 + t2 = 9
sub   s1,   s1,   s0          #s1 = s1 - s0 = 6
lw    t0,         0x78(zero)  #t0 = 175
lw    t1,         0x78(zero)  #t1 = 175
lw    t2,         0x7C(zero)  #t2 = 255
beq   t0,   t1,   0x14        #if (t0 == t1) branch to pc+5 (line 21)
addi  zero, zero, 0x00        #nop
addi  zero, zero, 0x00        #nop
addi  zero, zero, 0x00        #nop
addi  zero, zero, 0x00        #nop
beq   t1,   t2,   0x16        #if (t1 == t2) branch to pc+6 (line 28)
addi  zero, zero, 0x00        #nop
jal   t6,         0x1FFFA8    #jump to 0
addi  zero, zero, 0x00        #nop
addi  zero, zero, 0x00        #nop
addi  zero, zero, 0x00        #nop
addi  zero, zero, 0x00        #nop