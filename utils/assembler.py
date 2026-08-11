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
                "slti": ("I", 0b0010011, 0b010),
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
    with open("program.txt", "r") as f:
        instructions = f.read()
    instructions = [i.split() for i in instructions.replace(",", "").replace("(", " ").replace(")", "").replace("\t", "").split("\n")]
    types, regs = make_dicts()

    # first pass to record label addresses
    addr = {}
    counter = 0
    real = []
    for instr in instructions:
        if not instr:
            continue
        if instr[0] not in types:
            if not instr[0].endswith(":"):
                raise ValueError(f"unknown mnemonic or malformed label: {instr[0]!r}")
            addr[instr[0][:-1]] = counter
        else:
            counter += 4
            real.append(instr)
    instructions = real

    # second pass to form encoding
    machine = []
    info = 0
    for i in range(len(instructions)):
        instr = instructions[i]
        # check if instruction in dict
        if instr[0] in types:
            info = types[instr[0]]
        else:
            continue

        # encode instruction
        if info[0] == "R":
            machine.append(info[3]<<25 | regs[instr[3]]<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
        elif info[0] == "I":
            if instr[0] == "lw":
                imm = int(instr[2], 0) & 0xFFF
                machine.append(imm<<20 | regs[instr[3]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
            elif instr[0] == "srai":
                imm = (0b0100000<<5) | (int(instr[3], 0) & 0x1F)
                machine.append(imm<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
            elif instr[0] == "jalr":
                imm = (addr[instr[2]] if instr[2] in addr else int(instr[2], 0)) & 0xFFF
                machine.append(imm<<20 | regs[instr[3]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
            elif instr[0] == "slli":
                imm = int(instr[3], 0) & 0x1F
                machine.append(imm<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
            elif instr[0] == "srli":
                imm = int(instr[3], 0) & 0x1F
                machine.append(imm<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
            else:
                imm = int(instr[3], 0) & 0xFFF
                machine.append(imm<<20 | regs[instr[2]]<<15 | info[2]<<12 | regs[instr[1]]<<7 | info[1])
        elif info[0] == "S":
            imm4_0 = int(instr[2], 0) & 0x1F
            imm11_5 = (int(instr[2], 0) >> 5) & 0x7F
            machine.append(imm11_5<<25 | regs[instr[1]]<<20 | regs[instr[3]]<<15 | info[2]<<12 | imm4_0<<7 | info[1])
        elif info[0] == "B":
            label = instr[3]
            imm = addr[label] - 4 * i
            if not (-4096 <= imm < 4096):
                raise ValueError(f"branch offset {imm} out of range for {instr}")
            imm4_1 = (imm >> 1) & 0xF
            imm10_5 = (imm >> 5) & 0x3F
            imm11 = (imm >> 11) & 1
            imm12 = (imm >> 12) & 1
            machine.append(imm12<<31 | imm10_5<<25 | regs[instr[2]]<<20 | regs[instr[1]]<<15 | info[2]<<12 | imm4_1<<8 | imm11 << 7 | info[1])
        elif info[0] == "U":
            imm = (int(instr[2], 0) & 0xFFFFF) << 12
            machine.append(imm | regs[instr[1]]<<7 | info[1])
        elif info[0] == "J":
            label = instr[2]
            imm = addr[label] - 4 * i
            if not (-1048576 <= imm < 1048576):
                raise ValueError(f"jump offset {imm} out of range for {instr}")
            imm10_1 = (imm >> 1) & 0x3FF
            imm11 = (imm >> 11) & 1
            imm19_12 = (imm >> 12) & 0xFF
            imm20 = (imm >> 20) & 1
            machine.append(imm20<<31 | imm10_1<<21 | imm11<<20 | imm19_12<<12 | regs[instr[1]]<<7 | info[1])

    # write hex file
    with open("program.hex", "w") as f:
        for instr in machine:
            f.write(f"{instr & 0xFFFFFFFF:08x}\n")


if __name__ == "__main__":
    main()
