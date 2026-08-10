import control_pkg::*;
import alu_pkg::*;

module control (
    input logic [6:0] opcode,
    output logic regw,
    output logic memw,
    output logic memr,
    output alusrc_t alusrc,
    output logic branch,
    output memreg_t memregpc,
    output regpc_t regpc,
    output logic is_rish,
    output adderjalr_t use_br
    );

always_comb begin
    case (opcode)
        7'b0110011: begin // R
            regw   = 1;
            memw   = 0;
            memr   = 0;
            alusrc = use_reg;
            branch = 0;
            memregpc = use_alu;
            is_rish = 1;
            regpc = use_rs1;
            use_br = use_adder;
        end
        7'b0010011: begin // ADDI, SLLI, SRLI, SRAI
            regw   = 1;
            memw   = 0;
            memr   = 0;
            alusrc = use_imm;
            branch = 0;
            memregpc = use_alu;
            is_rish = 1;
            regpc = use_rs1;
            use_br = use_adder;
        end
        7'b0000011: begin // LW
            regw   = 1;
            memw   = 0;
            memr   = 1;
            alusrc = use_imm;
            branch = 0;
            memregpc = use_mem;
            is_rish = 0;
            regpc = use_rs1;
            use_br = use_adder;
        end
        7'b0100011: begin // SW
            regw   = 0;
            memw   = 1;
            memr   = 0;
            alusrc = use_imm;
            branch = 0;
            memregpc = use_alu;
            is_rish = 0;
            regpc = use_rs1;
            use_br = use_adder;
        end
        7'b1100011: begin // BEQ
            regw   = 0;
            memw   = 0;
            memr   = 0;
            alusrc = use_reg;
            branch = 1;
            memregpc = use_alu;
            is_rish = 0;
            regpc = use_rs1;
            use_br = use_adder;
        end
        7'b0110111: begin // LUI
            regw = 1;
            memw = 0;
            memr = 0;
            alusrc = use_imm;
            branch = 0;
            memregpc = use_immediate;
            is_rish = 0;
            regpc = use_rs1;
            use_br = use_adder;
        end
        7'b0010111: begin // AUIPC
            regw = 1;
            memw = 0;
            memr = 0;
            alusrc = use_imm;
            branch = 0;
            memregpc = use_alu;
            is_rish = 0;
            regpc = use_pc;
            use_br = use_adder;
        end
        7'b1101111: begin // JAL
            regw = 1;
            memw = 0;
            memr = 0;
            alusrc = use_imm;
            branch = 1;
            memregpc = use_pc_plus_4;
            is_rish = 0;
            regpc = use_pc;
            use_br = use_adder;
        end
        7'b1100111: begin // JALR
            regw = 1;
            memw = 0;
            memr = 0;
            alusrc = use_imm;
            branch = 1;
            memregpc = use_pc_plus_4;
            is_rish = 0;
            regpc = use_rs1;
            use_br = use_jalr;
        end
        default: begin
            regw   = 0;
            memw   = 0;
            memr   = 0;
            alusrc = use_reg;
            branch = 0;
            memregpc = use_alu;
            is_rish = 0;
            regpc = use_rs1;
            use_br = use_adder;
        end
    endcase
end

endmodule

module alu_control(
    input logic is_rish,
    input logic branch,
    input logic use_br,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output ops op
);

always_comb begin
    if (branch) begin
        if (use_br == use_jalr) begin
            op = ADD;
        end
        else begin
            op = SUB;
        end
    end
    else if (is_rish) begin
        case(funct3)
            3'b000: begin
                if (funct7[5]) begin
                    op = SUB;
                end
                else begin
                    op = ADD;
                end
            end
            3'b101: begin
                if (funct7[5]) begin
                    op = SRA;
                end
                else begin
                    op = SRL;
                end
            end
            3'b111: begin
                op = AND;
            end
            3'b110: begin
                op = OR;
            end
            3'b100: begin
                op = XOR;
            end
            3'b010: begin
                op = SLT;
            end
            3'b001: begin
                op = SLL;
            end
            default: begin
                op = ADD;
            end
        endcase
    end
    else begin
        op = ADD;
    end
end

endmodule