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
    funct3 != 3'b011;
}
constraint funct7_range {
    funct7 inside {7'b0000000, 7'b0100000};
}

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
