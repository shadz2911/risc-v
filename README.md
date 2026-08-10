# risc-v

A single-cycle RISC-V (RV32I subset) datapath implemented in SystemVerilog.

This isn't meant to be a comprehensive RV32I core — it implements just enough
of the ISA to demonstrate a working single-cycle datapath: fetch, decode,
execute, memory, and writeback, wired up end to end and verified in
simulation.

## Supported instructions

- R-type ALU: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLL`, `SRL`, `SRA`
- I-type ALU: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLLI`, `SRLI`, `SRAI`
- `LW`, `SW`
- `BEQ`
- `LUI`, `AUIPC`
- `JAL`, `JALR`

`SLTU`/`SLTIU`, the other branch variants (`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`),
and `FENCE`/`ECALL`/`EBREAK` are intentionally out of scope.

## Layout

```
alu/                  ALU and its opcode package (alu_pkg)
control_unit/         Main control unit + ALU control, opcode/alusrc/memreg package (control_pkg)
register/             32x32 register file (x0 hardwired to 0)
instruction_mem/      Instruction memory (reads program.hex)
data_mem/             Data memory
glue/                 PC, adders, muxes, and immediate generator tying it together
datapath.sv           Top-level module wiring all of the above into a single-cycle core
datapath_tb.sv        Basic testbench: loads program.hex and checks final register/memory state
datapath_full_tb.sv   Full instruction-set testbench: loads program_full.hex and asserts
                      pass/fail on every supported instruction, including branch/jump
                      control-flow correctness (see header comment in the file)
program.hex           Program image for datapath_tb.sv
program_full.hex      Program image for datapath_full_tb.sv, exercising every instruction
```

Each module under `alu/`, `control_unit/`, `register/`, `instruction_mem/`,
and `data_mem/` also has its own standalone testbench for unit-level
verification.

## Memory

Both instruction and data memory are 64 words (256 bytes) deep, word-addressed
via `addr[7:2]`. Addresses at or beyond `0x100` wrap around instead of
erroring, so keep program code and data within that range.

## Building and running

Simulated with [Icarus Verilog](http://iverilog.icarus.com/). Run from the
repo root so `program.hex`/`program_full.hex` resolve correctly:

```sh
iverilog -g2012 -o sim \
  alu/alu_pkg.sv control_unit/control_pkg.sv \
  alu/alu.sv register/register.sv instruction_mem/instruction.sv data_mem/data.sv \
  control_unit/control.sv \
  glue/pc.sv glue/pc_plus4.sv glue/branch_adder.sv glue/imm_gen.sv \
  glue/alu_src_mux.sv glue/pc_reg_mux.sv glue/jalr_adder_mux.sv \
  glue/writeback_mux.sv glue/pc_next_mux.sv \
  datapath.sv datapath_tb.sv

vvp sim
```

Swap `datapath_tb.sv` for `datapath_full_tb.sv` to run the full
instruction-set test instead — it prints a `pass`/`FAIL` line per register
and a final `ALL CHECKS PASSED` / `N CHECK(S) FAILED` summary.

This produces a `.vcd` waveform dump, viewable with a viewer such as
GTKWave.
