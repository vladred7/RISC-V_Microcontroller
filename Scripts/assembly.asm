
#Simple asm program for testing
.section .data
var1: .word 175
var2: 
   .word 255
var3: .word 0x0001
var4: .word 0x2
x: .word 0x0
y: .word 0x0
z: .word 0x0

.section .text
start:
   #Load the data in the internal registers
   lw    s0,         var1(gp)  #s0 = 175 #address = signed(var1 + gp)
   lw    s1,         var2(gp)  #s1 = 255
   lw    t1,         var3(gp)  #t1 = 1
   lw    t0,         var4(gp)  #t0 = 2

   #Perform some operations
   addi  t2,   t0,   0x05        #t2 = t0 + 5 = 7
   addi  t2,   t0,   0x05        #t2 = t0 + 5 = 7
   sw    t0,         x(gp)       #mem(x) = t0 = 2
   sw    t1,         y(gp)       #mem(y) = t1 = 1
   sw    t2,         z(gp)       #mem(z) = t2 = 7
   add   s0,   t0,   t1          #s0 = t0 + t1 = 3
   add   s1,   t0,   t2          #s1 = t0 + t2 = 9
   sub   s1,   s1,   s0          #s1 = s1 - s0 = 6
   lw    t0,         var1(gp)    #t0 = 175
   lw    t1,         var1(gp)    #t1 = 175
   lw    t2,         var2(gp)    #t2 = 255

   #Test Branch
   beq   t0,   t1,   label1      #if (t0 == t1) branch to pc+20 (line 31)
   addi  zero, zero, 0x00        #nop
   addi  zero, zero, 0x00        #nop
   addi  zero, zero, 0x00        #nop
   addi  zero, zero, 0x00        #nop

label1:                          #label 1 comment
   beq   t1,   t2,   label_02    #if (t1 == t2) branch to pc+8 (line 35)
   addi  zero, zero, 0x00        #nop

label_02:
   jal   t6,         start       #jump to 0
   addi  zero, zero, 0x00        #nop
   addi  zero, zero, 0x00        #nop
   addi  zero, zero, 0x00        #nop
   addi  zero, zero, 0x00        #nop
.section .end
