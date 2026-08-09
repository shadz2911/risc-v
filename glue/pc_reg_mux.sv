import control_pkg::*;

module pc_reg_mux(
    input logic [31:0] register,
    input logic [31:0] pc,
    input regpc_t regpc,
    output logic [31:0] out
);

assign out = (regpc == use_reg) ? register : pc;

endmodule
