module pc_next_mux(
    input logic [31:0] pc_plus4,
    input logic [31:0] branch_target,
    input logic branch,
    input logic zero,
    input memreg_t memalupc,
    output logic [31:0] pc_out 
);

always_comb begin
    if ((memalupc == use_pc_plus_4) | (branch && zero)) begin
        pc_out = branch_target;
    end
    else begin
        pc_out = pc_plus4;
    end
end

endmodule