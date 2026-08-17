import control_pkg::*;
import alu_pkg::*;

module mem_wb_reg (
    input logic clk,
    input logic reset,

    input logic regw_in,
    input memreg_t memregpc_in,
    input logic [31:0] mem_rdata_in,
    input logic [31:0] alu_result_in,
    input logic [4:0] rd_in,
    input logic [31:0] pc_plus4_in,
    input logic [31:0] imm_in,

    output logic regw_out,
    output memreg_t memregpc_out,
    output logic [31:0] mem_rdata_out,
    output logic [31:0] alu_result_out,
    output logic [4:0] rd_out,
    output logic [31:0] pc_plus4_out,
    output logic [31:0] imm_out
);

always_ff @(posedge clk) begin
    if (reset) begin
        regw_out <= 0;
        memregpc_out <= use_alu;
        mem_rdata_out <= 0;
        alu_result_out <= 0;
        rd_out <= 0;
        pc_plus4_out <= 0;
        imm_out <= 0;
    end
    else begin
        regw_out <= regw_in;
        memregpc_out <= memregpc_in;
        mem_rdata_out <= mem_rdata_in;
        alu_result_out <= alu_result_in;
        rd_out <= rd_in;
        pc_plus4_out <= pc_plus4_in;
        imm_out <= imm_in;
    end
end

endmodule