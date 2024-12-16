
    # Initialize registers
    lui t0, 0                  # Zero out t0
    lui t1, 0                  # Zero out t1
    lui t2, 0                  # Zero out t2
    auipc t3, 0                # t3 = PC-relative value for a local variable
    lw t4, 5(t3)               # Load the size of the array
    lw t5, 16(t4)              # Load the sum variable (initially 0)

    beq t0, t4, 5              # If counter t0 == size, exit loop
    lw t1, 0(t6)               # Load array[t0]
    add t5, t5, t1             # Add array[t0] to sum
    addi t6, t6, 4             # Move to the next array element (word size)
    addi t0, t0, 1             # Increment counter
    jal zero, 4                # Jump back to the loop start


    sw t5, 16(S3)              # Store the final sum back into memory

    # Demonstrating branching
    lui t1, 0x0                # Zero out t1
    lui t2, 0x0                # Zero out t2
    addi t1, t1, 50            # t1 = 50
    addi t2, t2, 100           # t2 = 100
    beq t1, t2, 14             # If t1 == t2, jump to branch_equal
    bne t1, t2, 12             # If t1 != t2, jump to branch_not_equal


    addi t3, zero, 0           # Branch Equal Logic (No-op)
    jal x2, x90                # Skip branch_not_equal


    addi t3, zero, 1           # Branch Not Equal Logic


    # Using JAL to jump to another label
    jal ZERO, h98


    # Arithmetic Examples
    addi t4, zero, 10          # Load 10 into t4
    addi t5, zero, 20          # Load 20 into t5
    add t6, t4, t5             # t6 = t4 + t5
    sub t2, t5, t4             # t7 = t5 - t4

    # Memory Example
    lw t1, 0(t0)               # Load msg value into t1
    addi t1, t1, 10            # t1 += 10
    sw t1, 0(t0)               # Store modified value back to msg

    # Branch Loop Example
    addi t0, zero, 0           # Reset t0 (counter)
    addi t2, zero, 5           # Loop 5 times

    beq t0, t2, 55             # Exit loop if t0 == t2
    addi t0, t0, 1             # Increment counter


    # Demonstrate LUI and AUIPC
    lui t3, 0x12345            # Load upper immediate into t3
    auipc t4, 0x1              # Load PC-relative immediate into t4

    # Final Exit
    addi a0, zero, 0           # Exit code 0
    jal zero, 0                # End program
