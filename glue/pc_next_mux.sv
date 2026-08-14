import control_pkg::*;

module pc_next_mux(
    input logic [31:0] pc_plus4,
    input logic [31:0] branch_target,
    input logic branch_taken,
    output logic [31:0] pc_out 
);

assign pc_out = branch_taken ? branch_target : pc_plus4;

endmodule