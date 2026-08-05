import alu_pkg::*;

module alu_tb;
    logic [31:0] a, b;
    logic [2:0] op;
    logic [31:0] result;
    logic zero;

    alu dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero)
    );

    initial begin
        op = ADD;
        a = 14;
        b = 10;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
        op = SUB;
        a = 14;
        b = 10;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
        op = AND;
        a = 4'b1001;
        b = 4'b0111;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
        op = OR;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
        op = XOR;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
        op = SLT;
        a = -1;
        b = 1;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, $signed(a), b, result, zero);
        a = 1;
        b = 3;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
        a = 3;
        b = 1;
        # 2;
        $display("op=%0d a=%0d b=%0d result=%0d zero=%b", op, a, b, result, zero);
    end

endmodule