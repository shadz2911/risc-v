import control_pkg::*;
import alu_pkg::*;

module control (
    input logic [6:0] opcode,
    output logic regw,
    output logic memw,
    output logic memr,
    output alusrc_t alusrc,
    output logic branch,
    output memreg_t memreg,
    output logic is_r
);

always_comb begin
    case (opcode)
        7'b0110011: begin // R
            regw   = 1;
            memw   = 0;
            memr   = 0;
            alusrc = use_reg;
            branch = 0;
            memreg = use_alu;
            is_r = 1;
        end
        7'b0010011: begin // ADDI
            regw   = 1;
            memw   = 0;
            memr   = 0;
            alusrc = use_imm;
            branch = 0;
            memreg = use_alu;
            is_r = 0;
        end
        7'b0000011: begin // LW
            regw   = 1;
            memw   = 0;
            memr   = 1;
            alusrc = use_imm;
            branch = 0;
            memreg = use_mem;
            is_r = 0;
        end
        7'b0100011: begin // SW
            regw   = 0;
            memw   = 1;
            memr   = 0;
            alusrc = use_imm;
            branch = 0;
            memreg = use_alu;
            is_r = 0;
        end
        7'b1100011: begin // BEQ
            regw   = 0;
            memw   = 0;
            memr   = 0;
            alusrc = use_reg;
            branch = 1;
            memreg = use_alu;
            is_r = 0;
        end
        default: begin
            regw   = 0;
            memw   = 0;
            memr   = 0;
            alusrc = use_reg;
            branch = 0;
            memreg = use_alu;
            is_r = 0;
        end
    endcase
end

endmodule

module alu_control(
    input logic is_r,
    input logic branch,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output ops op
);

always_comb begin
    if (branch) begin
        op = SUB;
    end
    else if (is_r) begin
        case(funct3)
            3'b000: begin
                if (funct7[5]) begin
                    op = SUB;
                end
                else begin
                    op = ADD;
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