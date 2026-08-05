module pc_plus4(
    input logic [31:0] pc,
    output logic [31:0] nextpc
);

assign nextpc = pc + 4;

endmodule