import control_pkg::*;
import alu_pkg::*;

module ex_mem_reg (
    input logic clk,
    input logic reset,

    input logic regw_in,
    input logic memw_in,
    input logic memr_in,
    input memreg_t memregpc_in,
    input logic [31:0] alu_result_in,
    input logic [31:0] rdata2_in,
    input logic [4:0] rd_in,
    input logic [31:0] pc_plus4_in,

    output logic regw_out,
    output logic memw_out,
    output logic memr_out,
    output memreg_t memregpc_out,
    output logic [31:0] alu_result_out,
    output logic [31:0] rdata2_out,
    output logic [4:0] rd_out,
    output logic [31:0] pc_plus4_out
);

always_ff @(posedge clk) begin
    if (reset) begin
        regw_out <= 0;
        memw_out <= 0;
        memr_out <= 0;
        memregpc_out <= use_alu;
        alu_result_out <= 0;
        rdata2_out <= 0;
        rd_out <= 0;
    end
    else begin
        regw_out <= regw_in;
        memw_out <= memw_in;
        memr_out <= memr_in;
        memregpc_out <= memregpc_in;
        alu_result_out <= alu_result_in;
        rdata2_out <= rdata2_in;
        rd_out <= rd_in;
    end
end

endmodule
