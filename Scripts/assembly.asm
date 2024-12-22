lw    s0,         0x78(zero)
lw    s1,         0x7C(zero)
lw    t0,         0x80(zero)
lw    t1,         0x84(zero)
addi  t2,   t0,   0x05
addi  t2,   t0,   0x05
sw    t0,         0xA0(zero)
sw    t1,         0xA4(zero)
sw    t2,         0xA8(zero)
add   s0,   t0,   t1
add   s1,   t0,   t2
sub   s1,   s1,   s0
lw    t0,         0x78(zero)
lw    t1,         0x78(zero)
lw    t2,         0x7C(zero)
beq   t0,   t1,   0x14
addi  zero, zero, 0x00
addi  zero, zero, 0x00
addi  zero, zero, 0x00
addi  zero, zero, 0x00
beq   t1,   t2,   0x16
addi  zero, zero, 0x00
jal   t6,         0x1FFFA8
addi  zero, zero, 0x00
addi  zero, zero, 0x00
addi  zero, zero, 0x00
addi  zero, zero, 0x00