# risc-v

A single-cycle RISC-V (RV32I subset) datapath implemented in SystemVerilog.

This isn't meant to be a comprehensive RV32I core — it implements just enough
of the ISA to demonstrate a working single-cycle datapath: fetch, decode,
execute, memory, and writeback, wired up end to end and verified in
simulation.

## Supported instructions

- R-type ALU: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`
- `ADDI`
- `LW`, `SW`
- `BEQ`

Shifts, other I-type ALU ops (`ANDI`/`ORI`/`XORI`/`SLTI`), the other branch
variants (`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`), jumps (`JAL`/`JALR`), and
`LUI`/`AUIPC` are intentionally out of scope.

## Layout

```
alu/              ALU and its opcode package (alu_pkg)
control_unit/     Main control unit + ALU control, opcode/alusrc/memreg package (control_pkg)
register/         32x32 register file (x0 hardwired to 0)
instruction_mem/  Instruction memory (reads program.hex)
data_mem/         Data memory
glue/             PC, adders, muxes, and immediate generator tying it together
datapath.sv       Top-level module wiring all of the above into a single-cycle core
datapath_tb.sv    Testbench: loads program.hex and checks final register/memory state
program.hex       Program image loaded into instruction memory at simulation start
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
repo root so `program.hex` resolves correctly:

```sh
iverilog -g2012 -o sim \
  alu/alu_pkg.sv control_unit/control_pkg.sv \
  alu/alu.sv register/register.sv instruction_mem/instruction.sv data_mem/data.sv \
  control_unit/control.sv \
  glue/pc.sv glue/pc_plus4.sv glue/branch_adder.sv glue/imm_gen.sv \
  glue/alu_src_mux.sv glue/writeback_mux.sv glue/pc_next_mux.sv \
  datapath.sv datapath_tb.sv

vvp sim
```

This produces `datapath.vcd`, viewable with a waveform viewer such as GTKWave.
