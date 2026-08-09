package control_pkg;
    typedef enum logic {
        use_reg = 1'b0, use_imm = 1'b1
    } alusrc_t;

    typedef enum logic [1:0] {
        use_alu = 2'b00, use_mem = 2'b01, use_pc_plus_4 = 2'b10
    } memreg_t;

    typedef enum logic {
        use_reg = 1'b0, use_pc = 1'b1
    } regpc_t;

    typedef enum logic {
        use_adder = 1'b0, use_jalr = 1'b1
    } adderjalr_t;
endpackage