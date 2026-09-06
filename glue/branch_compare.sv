module branch_compare(
    input logic [31:0] a,
    input logic [31:0] b,
    output logic beq
);

assign beq = (a == b);

endmodule
