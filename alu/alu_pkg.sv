package alu_pkg;
    typedef enum logic [2:0] {
        ADD=3'b000, SUB=3'b001, AND=3'b010, OR=3'b011, XOR=3'b100, SLT=3'b101
    } ops;
endpackage