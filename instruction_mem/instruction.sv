module instruction (
    input logic [31:0] raddr,
    output logic [31:0] instr
);

logic [31:0] instructions [0:63];

initial begin
    $readmemh("program.hex", instructions);
end

always_comb begin
    instr = instructions[raddr[7:2]];
end

endmodule
