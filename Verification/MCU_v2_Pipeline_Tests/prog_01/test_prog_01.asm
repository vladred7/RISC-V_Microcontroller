
#Simple asm program for testing
.section .data
pwm_cfg0: .word 0x00100028
pwm_cfg1: .word 0x00260000
pwm_ctr:  .word 0x0F000251
tmr_mch:  .word 40
tmr_ctr:  .word 0x00A00081
idx:      .word 100
check_s0_cnt: 
          .word 0
check_s1_cnt: 
          .word 0

.section .text
   #Preload bit masks for status bits read
   lui   A0,         0x80000000              #A0 = imm(0x80000000) mask for OFM_F flag from PWM0_CTRL
   lui   A1,         0x00002000              #A1 = imm(0x00002000) mask for MATCH0_F flag from TMR0_CTRL
   #Initialize S0 and S1 with 0
   addi  s0,   zero, 0x0                     #s0 = zero + 0 = 0
   and   s1,   zero, zero                    #s1 = zero & zero = 0
   #Load the idx that will be the number of iteration of the program
   lw    s11,        idx(gp)                 #s11 = idx
config_sfrs:
   #Configure the PWM0
   lw    t0,         pwm_cfg0(gp)            #t0 = mem(pwm_cfg0)
   sw    t0,         pwm0_cfg0(zero)         #SFR(pwm0_cfg0) = t0
   lw    t0,         pwm_cfg1(gp)            #t0 = mem(pwm_cfg1)
   sw    t0,         pwm0_cfg1(zero)         #SFR(pwm0_cfg1) = t0
   lw    t0,         pwm_ctr(gp)             #t0 = mem(pwm_ctr)
   sw    t0,         pwm0_ctrl(zero)         #SFR(pwm0_ctrl) = t0
   #Configure the TMR0
   lw    t0,         tmr_mch(gp)             #t0 = mem(tmr_mch)
   sw    t0,         TMR0_MATCH_VAL0(zero)   #SFR(TMR0_MATCH_VAL0) = t0
   lw    t0,         tmr_ctr(gp)             #t0 = mem(tmr_ctr)
   sw    t0,         TMR0_CTRL(zero)         #SFR(TMR0_CTRL) = t0
   
start_loop:
   #Read PWM0 and count how mant OF events have happened
   lw    t1,         pwm0_ctrl(zero)         #t1 = SFR(pwm0_ctrl)
   and   t2,   t1,   A0                      #t2 = t1 & A0 (select OFM_F bit)
   beq   t2,   zero, skip_inc_s0             #if (t2 == 0) skip the next 4 instructions
   xori  t6,   A0,   0xFFF                   #t6 = A0 ^ (-1) - equivalent to not(A0)
   and   t1,   t1,   t6                      #t1 = t1 & t6 (clear OFM_F bit from the SFR)
   sw    t1,         pwm0_ctrl(zero)         #SFR(pwm0_ctrl) = t1
   addi  s0,   s0,   1                       #s0 = s0 + 1
   
skip_inc_s0:
   #Read TMR0 and count how mant Match0 events have happened
   lw    t1,         TMR0_CTRL(zero)         #t1 = SFR(TMR0_CTRL)
   and   t2,   t1,   A1                      #t2 = t1 & A1 (select MATCH0_F bit)
   beq   t2,   zero, skip_inc_s1             #if (t2 == 0) skip the next 4 instructions
   xori  t6,   A1,   0xFFF                   #t6 = A1 ^ (-1) - equivalent to not(A1)
   and   t1,   t1,   t6                      #t2 = t2 & t6 (clear OFM_F bit from the SFR)
   addi  t1,   t1,   0x02                    #set the RST bit from TMR0_CTRL to reset the timer value
   sw    t1,         TMR0_CTRL(zero)         #SFR(TMR0_CTRL) = t1
   addi  s1,   s1,   1                       #s1 = s1 + 1
   
skip_inc_s1:
   #Decrease the index and jump to the begining of the loop if idx !=0
   beq   s11,  zero, end_program             #if (s11 == 0) branch to end_program
   addi  s11,  s11,  0xFFF                   #s11 = s11 - 1
   jal   zero,       start_loop              #jump to start_loop

end_program:
   #Write the results from the register bank to the memory for comparison with the gold mem
   sw    s0,         check_s0_cnt(gp)        #mem(check_s0_cnt) = s0
   sw    s1,         check_s1_cnt(gp)        #mem(check_s1_cnt) = s1
.section .end
