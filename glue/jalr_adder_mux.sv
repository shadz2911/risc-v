import control_pkg::*;

module jalr_adder_mux (
    input logic [31:0] jalr,
    input logic [31:0] adder,
    input adderjalr_t use_br,
    output logic [31:0] branch_target
);

assign branch_target = (use_br == (use_jalr)) ? jalr : adder;

endmodule