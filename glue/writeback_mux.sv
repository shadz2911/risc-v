import control_pkg::*;

module writeback_mux(
    input logic [31:0] alu,
    input logic [31:0] mem,
    input memreg_t memalu,
    output logic [31:0] out
);

assign out = (memalu == use_alu) ? alu : mem;

endmodule