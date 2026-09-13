import uvm_pkg::*;
`include "uvm_macros.svh"

class instr_transaction extends uvm_sequence_item;

// fields to randomize
rand bit [5:0] addr;

rand bit [6:0] opcode;
rand bit [4:0] rd, rs1, rs2;
rand bit [2:0] funct3;
rand bit [6:0] funct7;
rand bit signed [31:0] imm;

// contrains necessary fields for use later on
constraint opcode_range {
    opcode inside {7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011,
        7'b1100011, 7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111};
}
constraint funct3_range {
    if (opcode == 7'b1100011 || opcode == 7'b1100111)
        funct3 == 3'b000;
    else
        funct3 != 3'b011;
}
constraint funct7_range {
    if (funct3 == 3'b000 || funct3 == 3'b101)
        funct7 inside {7'b0000000, 7'b0100000};
    else
        funct7 == 7'b0000000;
}
constraint mem_base_reg {
    // x0 base keeps LW/SW/JALR's target predictable and aligned.
    if (opcode == 7'b0000011 || opcode == 7'b0100011 || opcode == 7'b1100111) rs1 == 0;
}
constraint reserve_x31 {
    rd != 31;
    rs1 != 31;
    rs2 != 31;
}
constraint jump_target_align {
    // Spike traps on a misaligned branch/jump/load/store address.
    if (opcode == 7'b1100011 || opcode == 7'b1101111 || opcode == 7'b1100111
        || opcode == 7'b0000011 || opcode == 7'b0100011) imm[1:0] == 2'b00;
}
// Done procedurally (not as a constraint) since XSim's solver rejects
// shifts/casts in constraint blocks. Keeps jump targets inside the real
// program -- otherwise Spike's target can land outside its mapped
// memory while the DUT's imem just wraps, desyncing the two forever.
function void post_randomize();
    int target;
    if (opcode == 7'b1100011 || opcode == 7'b1101111) begin
        target = $urandom_range(0, 63);
        imm = (target - int'(addr)) * 4;
    end
    else if (opcode == 7'b1100111) begin
        target = $urandom_range(0, 63);
        imm = target * 4;
    end
endfunction

`uvm_object_utils_begin(instr_transaction)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(opcode, UVM_ALL_ON)
    `uvm_field_int(rd, UVM_ALL_ON)
    `uvm_field_int(rs1, UVM_ALL_ON)
    `uvm_field_int(rs2, UVM_ALL_ON)
    `uvm_field_int(funct3, UVM_ALL_ON)
    `uvm_field_int(funct7, UVM_ALL_ON)
    `uvm_field_int(imm, UVM_ALL_ON)
`uvm_object_utils_end

function new(string name = "instr_transaction");
    super.new(name);
endfunction

// encodes randomly generated fileds into readable instructions
function bit [31:0] encode();
    bit [31:0] word;
    case (opcode)
        7'b0110011: // R-type: ADD/SUB/AND/OR/XOR/SLT/SLL/SRL/SRA
            word = {funct7, rs2, rs1, funct3, rd, opcode};

        7'b0010011: // I-type ALU: ADDI/ANDI/ORI/XORI/SLTI/SLLI/SRLI/SRAI
            if (funct3 == 3'b001 || funct3 == 3'b101)
                // shift variants: upper bits behave like funct7, low 5 bits are shamt
                word = {funct7, imm[4:0], rs1, funct3, rd, opcode};
            else
                word = {imm[11:0], rs1, funct3, rd, opcode};

        7'b0000011, // LW
        7'b1100111: // JALR
            word = {imm[11:0], rs1, funct3, rd, opcode};

        7'b0100011: // SW (S-type)
            word = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};

        7'b1100011: // BEQ (B-type)
            word = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};

        7'b0110111, // LUI
        7'b0010111: // AUIPC (U-type)
            word = {imm[31:12], rd, opcode};

        7'b1101111: // JAL (J-type)
            word = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};

        default:
            word = 32'h00000013; // ADDI x0, x0, 0 (nop) fallback
    endcase
    return word;
endfunction

endclass
