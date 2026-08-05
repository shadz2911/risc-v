import alu_pkg::*;

module alu(
    input logic [31: 0] a,
    input logic [31: 0] b,
    input logic [2: 0] op,
    output logic [31: 0] result,
    output logic zero
);

always_comb begin
    case (op)
        ADD: begin
            result = a + b;
        end
        SUB: begin
            result = a - b;
        end
        AND: begin
            result = a & b;
        end
        OR: begin
            result = a | b;
        end
        XOR: begin
            result = a ^ b;
        end
        SLT: begin
            result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        end
        default: begin
            result = 0;
        end
    endcase
    if (result == 0) begin
        zero = 1;
    end
    else begin
        zero = 0;
    end
end

endmodule
