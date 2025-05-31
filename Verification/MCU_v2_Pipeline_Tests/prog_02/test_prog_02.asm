//######################################## Header ########################################
//# Author: Vlad Rosu                                                                    #
//# Description: Program to generate tri-phase 120* PWM signals                          #
//########################################################################################

.section .data
pwm_cfg0: .word 0x00190031
pwm_cfg1: .word 0x00110000
pwm_ctr:  .word 0x0F000050
idx:      .word 100
check_s0_cnt: 
          .word 0
check_s1_cnt: 
          .word 0
check_s2_cnt: 
          .word 0

.section .text
   #Preload bit masks for status bits read
   lui   A0,         0x80000000              #A0 = imm(0x80000000) mask for OFM_F flag from PWM0_CTRL
   #Initialize S0 and S1 with 0
   addi  s0,   zero, 0x0                     #s0 = zero + 0 = 0
   addi  s1,   zero, 0x0                     #s1 = zero + 0 = 0
   addi  s2,   zero, 0x0                     #s2 = zero + 0 = 0
   #Load the idx that will be the number of iteration of the program
   lw    s11,        idx(gp)                 #s11 = idx
config_sfrs:
   #Configure the PWM0
   lw    t0,         pwm_cfg0(gp)            #t0 = mem(pwm_cfg0)
   sw    t0,         pwm0_cfg0(zero)         #SFR(pwm0_cfg0) = t0
   sw    t0,         pwm1_cfg0(zero)         #SFR(pwm1_cfg0) = t0
   sw    t0,         pwm2_cfg0(zero)         #SFR(pwm2_cfg0) = t0
   lw    t0,         pwm_cfg1(gp)            #t0 = mem(pwm_cfg1)
   sw    t0,         pwm0_cfg1(zero)         #SFR(pwm0_cfg1) = t0
   sw    t0,         pwm1_cfg1(zero)         #SFR(pwm1_cfg1) = t0
   sw    t0,         pwm2_cfg1(zero)         #SFR(pwm2_cfg1) = t0
   lw    t0,         pwm_ctr(gp)             #t0 = mem(pwm_ctr)
   sw    t0,         pwm0_ctrl(zero)         #SFR(pwm0_ctrl) = t0
   sw    t0,         pwm1_ctrl(zero)         #SFR(pwm1_ctrl) = t0
   sw    t0,         pwm2_ctrl(zero)         #SFR(pwm2_ctrl) = t0
   #Start the PWMs synchronized
   addi  t0,   t0,   1                       #Set the ON bit
   sw    t0,         pwm0_ctrl(zero)         #Start PWM0
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   sw    t0,         pwm1_ctrl(zero)         #Start PWM1
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   addi  zero, zero, 0                       #NOP
   sw    t0,         pwm2_ctrl(zero)         #Start PWM2

   #Store th mask for clearing OFM_F bits from PWM_CTRL SFRs
   xori  t6,   A0,   0xFFF                   #t6 = A0 ^ (-1) - equivalent to not(A0)
start_loop:
   #Read PWM0 and count how mant OF events have happened
   lw    t1,         pwm0_ctrl(zero)         #t1 = SFR(pwm0_ctrl)
   and   t2,   t1,   A0                      #t2 = t1 & A0 (select OFM_F bit)
   beq   t2,   zero, check_pwm1              #if (t2 == 0) skip the next 3 instructions
   and   t1,   t1,   t6                      #t1 = t1 & t6 (clear OFM_F bit from the SFR)
   sw    t1,         pwm0_ctrl(zero)         #SFR(pwm0_ctrl) = t1
   addi  s0,   s0,   1                       #s0 = s0 + 1
   
check_pwm1:
   #Read PWM1 and count how mant OF events have happened
   lw    t1,         pwm1_ctrl(zero)         #t1 = SFR(pwm1_ctrl)
   and   t2,   t1,   A0                      #t2 = t1 & A0 (select OFM_F bit)
   beq   t2,   zero, check_pwm2              #if (t2 == 0) skip the next 3 instructions
   and   t1,   t1,   t6                      #t1 = t1 & t6 (clear OFM_F bit from the SFR)
   sw    t1,         pwm1_ctrl(zero)         #SFR(pwm1_ctrl) = t1
   addi  s1,   s1,   1                       #s1 = s1 + 1

check_pwm2:
   #Read PWM2 and count how mant OF events have happened
   lw    t1,         pwm2_ctrl(zero)         #t1 = SFR(pwm2_ctrl)
   and   t2,   t1,   A0                      #t2 = t1 & A0 (select OFM_F bit)
   beq   t2,   zero, update_idx              #if (t2 == 0) skip the next 3 instructions
   and   t1,   t1,   t6                      #t1 = t1 & t6 (clear OFM_F bit from the SFR)
   sw    t1,         pwm2_ctrl(zero)         #SFR(pwm2_ctrl) = t1
   addi  s2,   s2,   1                       #s2 = s2 + 1
   
update_idx:
   #Decrease the index and jump to the begining of the loop if idx !=0
   beq   s11,  zero, end_program             #if (s11 == 0) branch to end_program
   addi  s11,  s11,  0xFFF                   #s11 = s11 - 1
   jal   zero,       start_loop              #jump to start_loop

end_program:
   #Write the results from the register bank to the memory for comparison with the gold mem
   sw    s0,         check_s0_cnt(gp)        #mem(check_s0_cnt) = s0
   sw    s1,         check_s1_cnt(gp)        #mem(check_s1_cnt) = s1
   sw    s2,         check_s2_cnt(gp)        #mem(check_s2_cnt) = s2

halt:
   jal   zero,       halt                    #infinite loop
   

.section .end
