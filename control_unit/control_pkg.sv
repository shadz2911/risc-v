package control_pkg;
    typedef enum logic {
        use_reg = 1'b0, use_imm = 1'b1
    } alusrc_t;

    typedef enum logic {
        use_alu = 1'b0, use_mem = 1'b1
    } memreg_t;
endpackage