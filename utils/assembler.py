def make_dicts(): 
    """
    TYPES DICTIONARY:
    R: (type, op, funct3, funct7)
    I: (type, op, funct3)
    S: (type, op, funct3)
    B: (type. op funct3)
    U: (type, op)
    J: (type, op)
    REGS DICTIONARY:
    Each register xY matched to its actual number Y
    """
    types = {"add": ("R", 0b0110011, 0b000, 0b0000000),
                "sub": ("R", 0b0110011, 0b000, 0b0100000),
                "and": ("R", 0b0110011, 0b111, 0b0000000),
                "or": ("R", 0b0110011, 0b110, 0b0000000),
                "xor": ("R", 0b0110011, 0b100, 0b0000000),
                "slt": ("R", 0b0110011, 0b010, 0b0000000),
                "sll": ("R", 0b0110011, 0b001, 0b0000000),
                "srl": ("R", 0b0110011, 0b101, 0b0000000),
                "sra": ("R", 0b0110011, 0b101, 0b0100000),
                "addi": ("I", 0b0010011, 0b000),
                "andi": ("I", 0b0010011, 0b111),
                "ori": ("I", 0b0010011, 0b110),
                "xori": ("I", 0b0010011, 0b100),
                "slli": ("I", 0b0010011, 0b001),
                "srli": ("I", 0b0010011, 0b101),
                "srai": ("I", 0b0010011, 0b101),
                "lw": ("I", 0b0000011, 0b010),
                "jalr": ("I", 0b1100111, 0b000),
                "sw": ("S", 0b0100011, 0b010),
                "beq": ("B", 0b1100011, 0b000),
                "lui": ("U", 0b0110111),
                "auipc": ("U", 0b0010111),
                "jal": ("J", 0b1101111)
              }

    regs = {}
    for i in range(32):
        regs["x" + str(i)] = i
    return types, regs

def main():
    instructions = ""
    # open file, make reg/types dicts and parse instructions
    with open("program_test.txt", "r") as f:
        instructions = f.read()
    instructions = [i.split(" ") for i in instructions.replace(",", "").replace("(", " ").replace(")", "").split("\n")]
    types, regs = make_dicts()

    # second pass to form encoding
    machine = []
    for instr in instructions:
        info = types[instr[0]]
        if info[0] == "R":
            machine.append(info[3]<<25 | regs[instr[3]]<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
        elif info[0] == "I":
            imm = int(instr[3]) & 0xFFF
            machine.append(imm<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
        elif info[0] == "S":
            imm11_5 = int(instr[2]) & 0xFE0
            imm4_0 = int(instr[2]) & 0x1F
            machine.append(imm11_5<<25 | regs[instr[1]]<<20 | regs[instr[3]]<<15 | info[2]<<12 | imm4_0<<7 | info[1])
            

    for i in machine:
        print(hex(i))

main()
