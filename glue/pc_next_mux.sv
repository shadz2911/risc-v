import control_pkg::*;

module pc_next_mux(
    input logic [31:0] pc_plus4,
    input logic [31:0] branch_target,
    input logic branch_taken,
    input logic predict_taken,
    input logic hit,
    input logic [31:0] target,
    input logic flush,
    input logic [31:0] pc_plus4_idex,

    output logic [31:0] pc_out
);

//assign pc_out = branch_taken ? branch_target : pc_plus4;

always_comb begin
    if (flush) begin
        pc_out = branch_taken ? branch_target : pc_plus4_idex;
    end else begin
        pc_out = (hit && predict_taken) ? target : pc_plus4;
    end
end

endmodule