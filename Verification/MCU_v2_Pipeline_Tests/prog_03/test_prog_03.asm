//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Program to wait 5ms for multiple iterations using the timer module      #
//########################################################################################

.section .data
dcoctr: .word 0x00000201
dcocnt: .word 0x0000007C
tmrctr: .word 0x00800581

check_cnt: 
         .word 0

.section .text
   #Initialize S0 with 0 and t6 with 5
   addi  s0,   zero, 0x0                     #s0 = zero + 0 = 0
   addi  t6,   zero, 0x5                     #t6 = zero + 5 = 5
config_sfrs:
   #Configure the DCO module
   lw    t0,         dcocnt(gp)              #t0 = mem(dcocnt)
   sw    t0,         DCO_CNT(zero)           #SFR(DCO_CNT) = t0
   lw    t0,         dcoctr(gp)              #t0 = mem(dcoctr)
   sw    t0,         DCO_CTRL(zero)          #SFR(DCO_CTRL) = t0
   #configure the Timer1 module
   addi  t0,   zero, 0x0                     #t0 = 0
   sw    t0,         TMR1_VAL(zero)          #SFR(TMR1_VAL) = t0
   lw    t0,         tmrctr(gp)              #t0 = mem(tmrctr)
   sw    t0,         TMR1_CTRL(zero)         #SFR(TMR1_CTRL) = t0
   
start_loop:
   #Read TMR1 Value and check if 5ms passed
   #First we need to trigger a read operation from the control SFR
   lw    t1,         TMR1_CTRL(zero)         #t1 = SFR(TMR1_CTRL)
   ori   t1,   t1,   0x8                     #t1 = t1 | 8(4'b1000) (set RD bit)
   sw    t1,         TMR1_CTRL(zero)         #SFR(TMR1_CTRL) = t1
   #After triggering the RD operation load the value from TMR_VAL
   lw    t1,         TMR1_VAL(zero)          #t1 = SFR(TMR1_VAL)
   #Compare the read value with the value 5 and jump to end program if is equal
   beq   t1,   t6,   end_program             #if (t1 == t6) skip the next 3 instructions
   jal   zero,       start_loop              #jump to start_loop 

end_program:
   #Stop the Timer and Read its value
   lw    t1,         TMR1_CTRL(zero)         #t1 = SFR(TMR1_CTRL)
   ori   t1,   t1,   0x48                    #t1 = t1 | 0x48 (8'b0100_1000) (set RD&Stop bit)
   sw    t1,         TMR1_CTRL(zero)         #SFR(TMR1_CTRL) = t1
   lw    t1,         TMR1_VAL(zero)          #t1 = SFR(TMR1_VAL)

   #Write the results from the register bank to the memory for comparison with the gold mem
   sw    t1,         check_cnt(gp)           #mem(check_cnt) = t1

halt:
   jal   zero,       halt                    #infinite loop
   

.section .end
