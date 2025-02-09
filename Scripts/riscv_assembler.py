######################################## Header ########################################
# Author: Vlad Rosu                                                                    #
# Description: This script computes the conversion of the assembly mnemonics of the    #
#              RV32I instruction set into machine code.                                #
# Input: Any assembly file (.asm) that contains only RV32I instructions                #
# Output: A binary/hex file containing the machine code                                #
########################################################################################

#TODOs
#add support for asm directives
#add support for pseudo-instructions

# RISC-V opcode dictionary
opc = {
   'lw'    : '0000011',   'LW'    : '0000011',    #load word
   'addi'  : '0010011',   'ADDI'  : '0010011',    #add immediate
   'auipc' : '0010111',   'AUIPC' : '0010111',    #add upper immediate to PC
   'sw'    : '0100011',   'SW'    : '0100011',    #store word
   'add'   : '0110011',   'ADD'   : '0110011',    #add
   'sub'   : '0110011',   'SUB'   : '0110011',    #subtract
   'lui'   : '0110111',   'LUI'   : '0110111',    #load upper immediate
   'beq'   : '1100011',   'BEQ'   : '1100011',    #branch if equal
   'bne'   : '1100011',   'BNE'   : '1100011',    #branch if not equal
   'jalr'  : '1100111',   'JALR'  : '1100111',    #jump and link register
   'jal'   : '1101111',   'JAL'   : '1101111'     #jump and link
}

#Instruction type dictionary
instrcution_type = {
   'lw'    : 'I',   'LW'    : 'I',    #load word
   'addi'  : 'I',   'ADDI'  : 'I',    #add immediate
   'auipc' : 'U',   'AUIPC' : 'U',    #add upper immediate to PC
   'sw'    : 'S',   'SW'    : 'S',    #store word
   'add'   : 'R',   'ADD'   : 'R',    #add
   'sub'   : 'R',   'SUB'   : 'R',    #subtract
   'lui'   : 'U',   'LUI'   : 'U',    #load upper immediate
   'beq'   : 'B',   'BEQ'   : 'B',    #branch if equal
   'bne'   : 'B',   'BNE'   : 'B',    #branch if not equal
   'jalr'  : 'I',   'JALR'  : 'I',    #jump and link register
   'jal'   : 'J',   'JAL'   : 'J'     #jump and link
}

# R/I/S/B-type Instruction Funct3 dictionary
function3 = {
   'lw'    :  '010',    'LW'    :  '010',
   'addi'  :  '000',    'ADDI'  :  '000',
   'sw'    :  '010',    'SW'    :  '010',
   'add'   :  '000',    'ADD'   :  '000',
   'sub'   :  '000',    'SUB'   :  '000',
   'beq'   :  '000',    'BEQ'   :  '000',
   'bne'   :  '001',    'BNE'   :  '001'
}

# R-type Instruction Funct7 dictionary
function7 = {
   'add'   :  '0000000',   'ADD'   :  '0000000',
   'sub'   :  '0100000',   'SUB'   :  '0100000'
}

# Register map dictionary
register_map = {
   'ZERO' : '00000',    'zero' : '00000',      'x0' : '00000',  # Constant Value of 0
     'RA' : '00001',      'ra' : '00001',      'x1' : '00001',  # Return Address
     'SP' : '00010',      'sp' : '00010',      'x2' : '00010',  # Stack Pointer
     'GP' : '00011',      'gp' : '00011',      'x3' : '00011',  # Global Pointer
     'TP' : '00100',      'tp' : '00100',      'x4' : '00100',  # Thread Pointer
     'T0' : '00101',      't0' : '00101',      'x5' : '00101',  # Temporary Register 0
     'T1' : '00110',      't1' : '00110',      'x6' : '00110',  # Temporary Register 1
     'T2' : '00111',      't2' : '00111',      'x7' : '00111',  # Temporary Register 2
     'S0' : '01000',      's0' : '01000',      'x8' : '01000',  # Saved Register 0/Frame Pointer = S0/FP
     'S1' : '01001',      's1' : '01001',      'x9' : '01001',  # Saved Register 1
     'A0' : '01010',      'a0' : '01010',     'x10' : '01010',  # Function argument 0 / Return value 0
     'A1' : '01011',      'a1' : '01011',     'x11' : '01011',  # Function argument 1 / Return value 1
     'A2' : '01100',      'a2' : '01100',     'x12' : '01100',  # Function argument 2
     'A3' : '01101',      'a3' : '01101',     'x13' : '01101',  # Function argument 3
     'A4' : '01110',      'a4' : '01110',     'x14' : '01110',  # Function argument 4
     'A5' : '01111',      'a5' : '01111',     'x15' : '01111',  # Function argument 5
     'A6' : '10000',      'a6' : '10000',     'x16' : '10000',  # Function argument 6
     'A7' : '10001',      'a7' : '10001',     'x17' : '10001',  # Function argument 7
     'S2' : '10010',      's2' : '10010',     'x18' : '10010',  # Saved Register 2
     'S3' : '10011',      's3' : '10011',     'x19' : '10011',  # Saved Register 3
     'S4' : '10100',      's4' : '10100',     'x20' : '10100',  # Saved Register 4
     'S5' : '10101',      's5' : '10101',     'x21' : '10101',  # Saved Register 5
     'S6' : '10110',      's6' : '10110',     'x22' : '10110',  # Saved Register 6
     'S7' : '10111',      's7' : '10111',     'x23' : '10111',  # Saved Register 7
     'S8' : '11000',      's8' : '11000',     'x24' : '11000',  # Saved Register 8
     'S9' : '11001',      's9' : '11001',     'x25' : '11001',  # Saved Register 9
    'S10' : '11010',     's10' : '11010',     'x26' : '11010',  # Saved Register 10
    'S11' : '11011',     's11' : '11011',     'x27' : '11011',  # Saved Register 11
     'T3' : '11100',      't3' : '11100',     'x28' : '11100',  # Temporary Register 3
     'T4' : '11101',      't4' : '11101',     'x29' : '11101',  # Temporary Register 4
     'T5' : '11110',      't5' : '11110',     'x30' : '11110',  # Temporary Register 5
     'T6' : '11111',      't6' : '11111',     'x31' : '11111'   # Temporary Register 6
}

# TODO don't forget about this, add support for implemented SFR
# SFR address map
sfr_space_start_addr = 0
sfr_map = {
    'CHIP_CTRL'         : '0',      'chip_ctrl'         : '0',  #
    'TMR0_CTRL'         : '0',      'tmr0_ctrl'         : '0',  #
    'TMR0_VAL'          : '0',      'tmr0_val'          : '0',  #
    'TMR0_MATCH_VAL0'   : '0',      'tmr0_match_val0'   : '0',  #
    'TMR0_MATCH_VAL1'   : '0',      'tmr0_match_val1'   : '0',  #
    'TMR1_CTRL'         : '0',      'tmr1_ctrl'         : '0',  #
    'TMR1_VAL'          : '0',      'tmr1_val'          : '0',  #
    'TMR1_MATCH_VAL0'   : '0',      'tmr1_match_val0'   : '0',  #
    'TMR1_MATCH_VAL1'   : '0',      'tmr1_match_val1'   : '0',  #
    'PWM0_CTRL'         : '0',      'pwm0_ctrl'         : '0',  #
    'PWM0_TMR'          : '0',      'pwm0_tmr'          : '0',  #
    'PWM0_CFG0'         : '0',      'pwm0_cfg0'         : '0',  #
    'PWM0_CFG1'         : '0',      'pwm0_cfg1'         : '0',  #
    'PWM1_CTRL'         : '0',      'pwm1_ctrl'         : '0',  #
    'PWM1_TMR'          : '0',      'pwm1_tmr'          : '0',  #
    'PWM1_CFG0'         : '0',      'pwm1_cfg0'         : '0',  #
    'PWM1_CFG1'         : '0',      'pwm1_cfg1'         : '0',  #
    'PWM2_CTRL'         : '0',      'pwm2_ctrl'         : '0',  #
    'PWM2_TMR'          : '0',      'pwm2_tmr'          : '0',  #
    'PWM2_CFG0'         : '0',      'pwm2_cfg0'         : '0',  #
    'PWM2_CFG1'         : '0',      'pwm2_cfg1'         : '0',  #
    'DCO_CTRL'          : '0',      'dco_ctrl'          : '0',  #
    'DCO_CNT'           : '0',      'dco_cnt'           : '0'   #
}





#+------------------------------------------------------------------------------------+#
#| Function: bin2hex_32bit(string)                                                    |#
#| Description: This function translates an 32 bit long binary value representeas     |#
#|    as a string to a string that containes the hexadecimal value with the specific  |#
#|    prefix '0x'                                                                     |#
#| Input:                                                                             |#
#|    string - a 32bit binary number represented as a string                          |#
#| Output:                                                                            |#
#|    string - a 32bit hexadecimal number represented as a string with '0x' prefix    |#
#+------------------------------------------------------------------------------------+#
def bin2hex_32bit(bin_str):
    #Verify that the input string is 32 bits long
    if(len(bin_str) != 32):
        raise ValueError("Binary string is not 32 bits long!")
    
    hex_str = hex(int(bin_str,2))[2:]   #strip the '0x' prefix for now
    hex_str = hex_str.zfill(8)          #make the hex number 8=32/4 characters long
    hex_str = '0x' + hex_str            #add back the '0x' prefix
    
    return hex_str


#+------------------------------------------------------------------------------------+#
#| Function: strval2strbin(string,int)                                                |#
#| Description: This function computes an input string that is either a value         |#
#|    represented in decimal or in hexadecimal and translate that value into the      |#
#|    binary format that has the length specified as an int argument                  |#
#| Input:                                                                             |#
#|    string - a decimal/hexadecimal number represented as a string                   |#
#|    int - an integer that specifies the length of the string that contains the      |#
#|          binary number                                                             |#
#| Output:                                                                            |#
#|    string - a binary number represented as a string of the specified length        |#
#+------------------------------------------------------------------------------------+#
def strval2strbin(val_str,length):
    is_hex = 0
    #Remove the "`" that can be used as a prefix for x or h in hexadecimal
    val_str = val_str.replace("'", "")
    
    #Test if the value is in hexadecimal and remove the prefix
    if val_str.startswith('0x') or val_str.startswith('0h'):
        val_str = val_str[2:]
        is_hex = 1
    elif val_str.startswith('x') or val_str.startswith('h'):
        val_str = val_str[1:]
        is_hex = 1

    #Convert the string to an integer based on its representation
    if is_hex:
        dec_val = int(val_str, 16)
    else:
        dec_val = int(val_str)

    #Convert the decimal number to a binary number string of the specified length
    bin_str = format(dec_val, f'0{length}b')
    
    #Test is the value can be represented on the specified number of bits
    if len(bin_str) > length:
        raise ValueError(f"Value {dec_val} cannot fit in {length} bits length!")

    return bin_str
     

#+------------------------------------------------------------------------------------+#
#| Function: compute_signed_Nbit_ta(int, int, int)                                    |#
#| Description: This function computes the difference between current PC and BTA/JTA  |#
#|    (branch/jump target address) on N bit resolution                                |#
#| Input:                                                                             |#
#|    int - resolution in bits N                                                      |#
#|    int - current PC address                                                        |#
#|    int - BT/JT PC address                                                          |#
#| Output:                                                                            |#
#|    string - the hexadecimal signed Nbit value                                      |#
#+------------------------------------------------------------------------------------+#
def compute_signed_Nbit_ta(N, PC_current, target_addr):
    #Bits selection mask based on operation resolution
    mask = (2**N) - 1 
    #Calculate the difference between the addresses
    value = target_addr - PC_current
    #Truncate restult to N LSbits
    value &= mask
    #Return the N bit value as a string in hexadecimal
    return hex(value)


#+------------------------------------------------------------------------------------+#
#| Function: build_Rtype_instr(string)                                                |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and build the specific R-Type binary instruction for a RISC-V 32bit    |#
#|    microcontroller                                                                 |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#| Output:                                                                            |#
#|    string - a binary instruction coded as a R-Type instruction for RISC-V 32bit    |#
#+------------------------------------------------------------------------------------+#
def build_Rtype_instr(instr_line):
    op       = opc[instr_line[0]]
    rd       = register_map[instr_line[1]]
    funct3   = function3[instr_line[0]]
    rs1      = register_map[instr_line[2]]
    rs2      = register_map[instr_line[3]]
    funct7   = function7[instr_line[0]]
    
    rtype_instr =  funct7 + rs2 + rs1 + funct3 + rd + op
    return rtype_instr


#+------------------------------------------------------------------------------------+#
#| Function: build_Itype_instr(string)                                                |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and build the specific I-Type binary instruction for a RISC-V 32bit    |#
#|    microcontroller                                                                 |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#| Output:                                                                            |#
#|    string - a binary instruction coded as a I-Type instruction for RISC-V 32bit    |#
#+------------------------------------------------------------------------------------+#
def build_Itype_instr(instr_line):
    immediate_field_length = 12
    
    #EXCEPTION for load operations
    #This ['lw', 'x6', '0(x7)'] should become this ['lw', 'x6', 'x7', '0'] for easier processing
    if instr_line[0].startswith('l') or instr_line[0].startswith('L'):
        instr_line[2] = instr_line[2].replace(")", "")  #removing last ")"
        instr_line[2] = instr_line[2].split(sep='(')    #splitting third element in 2 elemnts
        instr_line = [instr_line[0],instr_line[1],instr_line[2][1],instr_line[2][0]] #reorder the elements in the initial string
    
    op        = opc[instr_line[0]]
    rd        = register_map[instr_line[1]]
    funct3    = function3[instr_line[0]]
    rs1       = register_map[instr_line[2]]
    imm_11_0  = strval2strbin(instr_line[3],immediate_field_length)
    
    itype_instr =  imm_11_0 + rs1 + funct3 + rd + op
    return itype_instr


#+------------------------------------------------------------------------------------+#
#| Function: build_Stype_instr(string)                                                |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and build the specific S-Type binary instruction for a RISC-V 32bit    |#
#|    microcontroller                                                                 |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#| Output:                                                                            |#
#|    string - a binary instruction coded as a S-Type instruction for RISC-V 32bit    |#
#+------------------------------------------------------------------------------------+#
def build_Stype_instr(instr_line):
    immediate_field_length = 12
    
    #This ['sw', 'x6', '0(x7)'] should become this ['sw', 'x6', 'x7', '0'] for easier processing
    instr_line[2] = instr_line[2].replace(")", "")  #removing last ")"
    instr_line[2] = instr_line[2].split(sep='(')    #splitting third element in 2 elemnts
    instr_line = [instr_line[0],instr_line[1],instr_line[2][1],instr_line[2][0]] #reorder the elements in the initial string
    
    #Compute the entire immediate value into one string
    imm_11_0  = strval2strbin(instr_line[3],immediate_field_length)
    #Calculate the index for splitting the LSB and MSB from the 12 bit immediate value
    split_index = immediate_field_length-1-4
    
    op        = opc[instr_line[0]]
    imm_4_0   = imm_11_0[split_index:] #5LSbits of the 12 bit immediate are at the end of the string
    funct3    = function3[instr_line[0]]
    rs1       = register_map[instr_line[2]]
    rs2       = register_map[instr_line[1]]
    imm_11_5  = imm_11_0[:split_index] #7MSbits of the 12 bit immediate are at the start of the string
    
    stype_instr =  imm_11_5 + rs2 + rs1 + funct3 + imm_4_0 + op
    return stype_instr


#+------------------------------------------------------------------------------------+#
#| Function: build_Btype_instr(string)                                                |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and build the specific B-Type binary instruction for a RISC-V 32bit    |#
#|    microcontroller                                                                 |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#|    int - current PC address                                                        |#
#| Output:                                                                            |#
#|    string - a binary instruction coded as a B-Type instruction for RISC-V 32bit    |#
#+------------------------------------------------------------------------------------+#
def build_Btype_instr(instr_line, current_PC):
    immediate_field_length = 13
    
    #if the instruction contains a label, swap the label with the PC address
    if(instr_line[3] in symbol_table):
        #branch address is relative to the current PC
        instr_line[3] = compute_signed_Nbit_ta(immediate_field_length, current_PC, symbol_table[instr_line[3]])
    
    imm_12_0  = strval2strbin(instr_line[3],immediate_field_length)
    
    op        = opc[instr_line[0]]
    imm_11    = imm_12_0[(immediate_field_length-1)-11]
    imm_4_1   = imm_12_0[(immediate_field_length-1)-4:(immediate_field_length-1)] 
    funct3    = function3[instr_line[0]]
    rs1       = register_map[instr_line[2]]
    rs2       = register_map[instr_line[1]]
    imm_10_5  = imm_12_0[(immediate_field_length-1)-10:(immediate_field_length-5)]
    imm_12    = imm_12_0[(immediate_field_length-1)-12]

    btype_instr = imm_12 + imm_10_5 + rs2 + rs1 + funct3 + imm_4_1 + imm_11 + op
    return btype_instr


#+------------------------------------------------------------------------------------+#
#| Function: build_Utype_instr(string)                                                |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and build the specific U-Type binary instruction for a RISC-V 32bit    |#
#|    microcontroller                                                                 |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#| Output:                                                                            |#
#|    string - a binary instruction coded as a U-Type instruction for RISC-V 32bit    |#
#+------------------------------------------------------------------------------------+#
def build_Utype_instr(instr_line):
    immediate_field_length = 32
    
    imm_31_0  = strval2strbin(instr_line[2],immediate_field_length)
    
    op        = opc[instr_line[0]]
    rd        = register_map[instr_line[1]]
    imm_31_12 = imm_31_0[(immediate_field_length-1)-31:(immediate_field_length-12)]
    
    utype_instr = imm_31_12 + rd + op
    return utype_instr


#+------------------------------------------------------------------------------------+#
#| Function: build_Jtype_instr(string)                                                |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and build the specific J-Type binary instruction for a RISC-V 32bit    |#
#|    microcontroller                                                                 |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#|    int - current PC address                                                        |#
#| Output:                                                                            |#
#|    string - a binary instruction coded as a J-Type instruction for RISC-V 32bit    |#
#+------------------------------------------------------------------------------------+#
def build_Jtype_instr(instr_line, current_PC):
    immediate_field_length = 21
    
    #if the instruction contains a label, swap the label with the PC address
    if(instr_line[2] in symbol_table):
        #jump address is relative to the current PC
        instr_line[2] = compute_signed_Nbit_ta(immediate_field_length, current_PC, symbol_table[instr_line[2]])
    
    imm_20_0  = strval2strbin(instr_line[2],immediate_field_length)
    
    op        = opc[instr_line[0]]
    rd        = register_map[instr_line[1]]
    imm_19_12 = imm_20_0[(immediate_field_length-1)-19:(immediate_field_length-12)]
    imm_11    = imm_20_0[(immediate_field_length-1)-11]
    imm_10_1  = imm_20_0[(immediate_field_length-1)-10:(immediate_field_length-1)]
    imm_20    = imm_20_0[(immediate_field_length-1)-20]
     
    jtype_instr = imm_20 + imm_10_1 + imm_11 + imm_19_12 + rd + op
    return jtype_instr


#+------------------------------------------------------------------------------------+#
#| Function: translate_menmonic(string)                                               |#
#| Description: This function computes the input string represented by an assembly    |#
#|    menmonic and it select base on the instruction type the specific binary encode  |#
#|    function                                                                        |#
#| Input:                                                                             |#
#|    string - an RISC-V assembly mnemonic (RV32I)                                    |#
#|    int - current PC address to be used for branch/jump instructions                |#
#| Output:                                                                            |#
#|    string - the binary instruction code for the specific assembly mnemonic         |#
#+------------------------------------------------------------------------------------+#
def translate_menmonic(instr_line, current_PC):
    instr_line = instr_line.replace(",", "")
    instr_line = instr_line.split()
    instr_type = instrcution_type[instr_line[0]]
    
    if  (instr_type == 'R'):
        binary_instr = build_Rtype_instr(instr_line)
    elif(instr_type == 'I'):
        binary_instr = build_Itype_instr(instr_line)
    elif(instr_type == 'S'):
        binary_instr = build_Stype_instr(instr_line)
    elif(instr_type == 'B'):
        binary_instr = build_Btype_instr(instr_line, current_PC)
    elif(instr_type == 'U'):
        binary_instr = build_Utype_instr(instr_line)
    elif(instr_type == 'J'):
        binary_instr = build_Jtype_instr(instr_line, current_PC)

    return binary_instr


#+------------------------------------------------------------------------------------+#
#| Function: main()                                                                   |#
#| Description: This is the main function                                             |#
#| Input:                                                                             |#
#| Output:                                                                            |#
#+------------------------------------------------------------------------------------+#
def main():
    #Declare a pointer to the global string
    global mnemonics
    #Initialize PC with 0
    PC = 0
    
    #First Iteration
    #1) Strip the assembly code of comments & empty lines & spaces
    #2) Build the symbol table map
    #3) TODO add support for data (data declaration) and text sections
    with open("assembly.asm", "r") as asm_file:
        for line in asm_file:
            #Strip all whitespaces from the current line
            line = line.strip()
            #If the line is empty skip it
            if not line:
                continue
            #If the line starts with '#' skip it
            if line.startswith("#"):
                continue
            #Remove the comments from the lines that contains instructions
            line = line.split('#', 1)[0].strip()
            
            if line.endswith(":"): #if line is an label
                symbol_table[line[:-1]] = PC #save the PC for the label
                #Labels are not real intructions, that is why they should not increase the PC value, only save it
            else: #if the line is not a label than it is an instruction
                mnemonics = mnemonics + line + '\n'
                #Update PC address
                PC += 4

    #Close the ASM code file:
    asm_file.close()

    #Split the code into a list of instructions
    mnemonics = mnemonics.split('\n')
    #Remove last empty string
    mnemonics.remove('')
    #Reinitialize the PC with 0 for the second iteration
    PC = 0

    #Second Iteration
    #1) Convert the menmonics into machine code
    #2) Generate the programming .bin/.hex files         
    with open("machine_code.bin", "w") as bin_file, \
         open("machine_code.hex", "w") as hex_file:
      
        for line in mnemonics:
            #Trasnslate the assembly instruction into binary machine code
            bin_line = translate_menmonic(line, PC)
            #Transfrom the binary coded instruction in hexadecimal as well
            hex_line = bin2hex_32bit(bin_line)
            #Write the machine code files in their specific format binary/hex
            bin_file.write(bin_line + '\n')
            hex_file.write(hex_line + '\n')
            #Update PC
            PC += 4

    #Close the .bin and .hex files:
    bin_file.close()
    hex_file.close()


#+------------------------------------------------------------------------------------+#
#|                                Global Variable Space                               |#
#+------------------------------------------------------------------------------------+#
#Declare the symbol table as a map (dictionary)
symbol_table = {}
#Declare a string in which the mnemonics will be stored
mnemonics = ''


#Execute the main()
main() 