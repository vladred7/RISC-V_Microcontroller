
#Simple asm program for testing
.section .data
pwm_cfg0: .word 0x0005000A
pwm_cfg1: .word 0x00080000
pwm_ctr:  .word 0x0F000151
idx:      .word 30

.section .text
start:
   #Configure the PWM
   lw    t0,         pwm_cfg0(gp)      #t0 = pwm_cfg0
   sw    t0,         pwm0_cfg0(zero)   #SFR(pwm0_cfg0) = t0
   lw    t0,         pwm_cfg1(gp)      #t0 = pwm_cfg1
   sw    t0,         pwm0_cfg1(zero)   #SFR(pwm0_cfg1) = t0
   lw    t0,         pwm_ctr(gp)       #t0 = pwm_ctr
   sw    t0,         PWM0_CTRL(zero)   #SFR(PWM0_CTRL) = t0
compute:
   #Perform some operations
   addi  t2,   zero, 0x05              #t2 = zero + 5 = 5
   add   s0,   t2,   t2                #s0 = t2 + t2 = 10
   addi  t2,   t2,   0x05              #t2 = t2 + 5 = 10
   lw    t3,         idx(gp)           #t3 = idx

   #Test Branch
loop:
   beq   t3,   zero, pwm_reset_tmr     #if (t3 == 0) branch to pwm_reset_tmr
   addi  t3,   t3,   0xFFF             #t3 = t3 - 1
   jal   t6,         loop              #jump to loop

pwm_reset_tmr:
   lw    t0,         pwm_ctr(gp)       #t0 = pwm_ctr
   addi  t0,   t0,   2
   sw    t0,         PWM0_CTRL(zero)   #SFR(PWM0_CTRL) = t0
   jal   t6,         compute           #jump to compute
.section .end
