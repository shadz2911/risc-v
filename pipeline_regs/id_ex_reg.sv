import control_pkg::*;
import alu_pkg::*;

module id_ex_reg (
    input logic clk,
    input logic reset,
    input logic flush,

    input logic regw_in,
    input logic memw_in,
    input logic memr_in,
    input alusrc_t alusrc_in,
    input logic branch_in,
    input memreg_t memregpc_in,
    input regpc_t regpc_in,
    input logic is_rish_in,
    input adderjalr_t use_br_in,
    input logic [31:0] imm_in,
    input logic [2:0] funct3_in,
    input logic [6:0] funct7_in,
    input logic [31:0] rdata1_in,
    input logic [31:0] rdata2_in,
    input logic [31:0] current_pc_in,
    input logic [4:0] rd_in,
    input logic [4:0] rs1_in,
    input logic [4:0] rs2_in,
    input logic [31:0] pc_plus4_in,

    output logic regw_out,
    output logic memw_out,
    output logic memr_out,
    output alusrc_t alusrc_out,
    output logic branch_out,
    output memreg_t memregpc_out,
    output regpc_t regpc_out,
    output logic is_rish_out,
    output adderjalr_t use_br_out,
    output logic [31:0] imm_out,
    output logic [2:0] funct3_out,
    output logic [6:0] funct7_out,
    output logic [31:0] rdata1_out,
    output logic [31:0] rdata2_out,
    output logic [31:0] current_pc_out,
    output logic [4:0] rd_out,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [31:0] pc_plus4_out
);

// no need for freezing for load-use and RAW hazards

always_ff @(posedge clk) begin
    if (reset || flush) begin
        regw_out <= 0;
        memw_out <= 0;
        memr_out <= 0;
        alusrc_out <= use_reg;
        branch_out <= 0;
        memregpc_out <= use_alu;
        regpc_out <= use_rs1;
        is_rish_out <= 0;
        use_br_out <= use_adder;
        imm_out <= 0;
        funct3_out <= 0;
        funct7_out <= 0;
        rdata1_out <= 0;
        rdata2_out <= 0;
        current_pc_out <= 0;
        rd_out <= 0;
        rs1_out <= 0;
        rs2_out <= 0;
        pc_plus4_out <= 0;
    end
    else begin
        regw_out <= regw_in;
        memw_out <= memw_in;
        memr_out <= memr_in;
        alusrc_out <= alusrc_in;
        branch_out <= branch_in;
        memregpc_out <= memregpc_in;
        regpc_out <= regpc_in;
        is_rish_out <= is_rish_in;
        use_br_out <= use_br_in;
        imm_out <= imm_in;
        funct3_out <= funct3_in;
        funct7_out <= funct7_in;
        rdata1_out <= rdata1_in;
        rdata2_out <= rdata2_in;
        current_pc_out <= current_pc_in;
        rd_out <= rd_in;
        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        pc_plus4_out <= pc_plus4_in;
    end
end

endmodule