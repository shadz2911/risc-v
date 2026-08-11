# program_full.asm
#
# Reference assembly for program_full.hex, covering every instruction in
# the datapath's supported RV32I subset (see datapath_full_tb.sv for the
# expected register values this program produces).
#
# Each line's trailing comment shows [address, machine code] for
# cross-checking your own assembler's output word-for-word.
#
# Register conventions used below:
#   x1-x26  hold direct results of the instruction being tested
#   x27-x31 are control-flow proof/poison registers

    addi x1, x0, 5                                                 # [0x00, 00500093]
    addi x2, x0, 3                                                 # [0x04, 00300113]
    add  x3, x1, x2                                                # [0x08, 002081B3]
    sub  x4, x1, x2                                                # [0x0C, 40208233]
    and  x5, x1, x2                                                # [0x10, 0020F2B3]
    or   x6, x1, x2                                                # [0x14, 0020E333]
    xor  x7, x1, x2                                                # [0x18, 0020C3B3]
    slt  x8, x2, x1                                                # [0x1C, 00112433]
    slt  x9, x1, x2                                                # [0x20, 0020A4B3]
    addi x10, x0, 2                                                # [0x24, 00200513]
    sll  x11, x1, x10                                              # [0x28, 00A095B3]
    srl  x12, x1, x10                                              # [0x2C, 00A0D633]
    addi x13, x0, -8                                               # [0x30, FF800693]
    sra  x14, x13, x10                                             # [0x34, 40A6D733]
    andi x15, x1, 3                                                # [0x38, 0030F793]
    ori  x16, x1, 2                                                # [0x3C, 0020E813]
    xori x17, x1, 3                                                # [0x40, 0030C893]
    slti x18, x2, 5                                                # [0x44, 00512913]
    slli x19, x1, 2                                                # [0x48, 00209993]
    srli x20, x1, 1                                                # [0x4C, 0010DA13]
    srai x21, x13, 1                                               # [0x50, 4016DA93]
    sw   x1, 0(x0)                                                 # [0x54, 00102023]
    lw   x22, 0(x0)                                                # [0x58, 00002B03]
    beq  x1, x2, L1  # not taken (5 != 3)                          # [0x5C, 00208463]
    addi x27, x0, 111  # runs only if not-taken worked             # [0x60, 06F00D93]
L1:
    beq  x1, x1, L2  # taken (5 == 5)                              # [0x64, 00108463]
    addi x28, x28, 999  # poison: should be skipped                # [0x68, 3E7E0E13]
L2:
    addi x29, x0, 222  # proof: resumed after taken branch         # [0x6C, 0DE00E93]
    lui  x23, 0x12345                                              # [0x70, 12345BB7]
    auipc x24, 1                                                   # [0x74, 00001C17]
    jal  x25, JT                                                   # [0x78, 00800CEF]
    addi x30, x30, 333  # poison: should be skipped by JAL         # [0x7C, 14DF0F13]
JT:
    addi x31, x31, 444  # proof: JAL landed                        # [0x80, 1BCF8F93]
    jalr x26, JRT(x0)  # base x0 -> target = absolute addr of JRT  # [0x84, 08C00D67]
    addi x30, x30, 777  # poison: should be skipped by JALR        # [0x88, 309F0F13]
JRT:
    addi x31, x31, 888  # proof: JALR landed                       # [0x8C, 378F8F93]
