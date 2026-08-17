# risc-v

A RISC-V (RV32I subset) core implemented in SystemVerilog, in two flavors:
a single-cycle datapath and a 5-stage pipelined datapath with forwarding
and hazard detection.

## Supported instructions

- R-type ALU: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLL`, `SRL`, `SRA`
- I-type ALU: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLLI`, `SRLI`, `SRAI`
- `LW`, `SW`
- `BEQ`
- `LUI`, `AUIPC`
- `JAL`, `JALR`

`SLTU`/`SLTIU`, the other branch variants (`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`),
and `FENCE`/`ECALL`/`EBREAK` are intentionally out of scope. Both the
single-cycle and pipelined cores support the same subset.

## Layout

```
alu/                  ALU and its opcode package (alu_pkg)
control_unit/         Main control unit + ALU control, opcode/alusrc/memreg package (control_pkg)
register/             32x32 register file (x0 hardwired to 0)
instruction_mem/      Instruction memory (reads program.hex)
data_mem/             Data memory
glue/                 PC, adders, muxes, and immediate generator tying it together
pipeline_regs/        IF/ID, ID/EX, EX/MEM, MEM/WB pipeline registers
hazard/                forward_unit.sv (EX/MEM and MEM/WB forwarding) and
                       hazard_detect.sv (load-use stall detection)
datapath.sv            Top-level module wiring the single-cycle core
datapath_pipelined.sv  Top-level module wiring the 5-stage pipelined core
datapath_tb.sv         Basic single-cycle testbench: loads program.hex and checks
                        final register/memory state
datapath_full_tb.sv    Full instruction-set testbench for the single-cycle core:
                        loads program_full.hex and asserts pass/fail on every
                        supported instruction, including branch/jump control-flow
                        correctness (see header comment in the file)
tests/                 Testbenches for the pipelined core (see Testing, below)
program.hex             Program image for datapath_tb.sv
program_full.hex        Program image for datapath_full_tb.sv, exercising every instruction
```

Each module under `alu/`, `control_unit/`, `register/`, `instruction_mem/`,
and `data_mem/` also has its own standalone testbench for unit-level
verification.

## Pipelining

`datapath_pipelined.sv` reuses every module from the single-cycle core,
splitting execution across 5 stages (fetch, decode, execute, memory,
writeback) connected by the pipeline registers in `pipeline_regs/`. Two
hazard classes need explicit handling:

**Data hazards (forwarding).** `hazard/forward_unit.sv` forwards a
producer's result to a consumer's EX stage without waiting for it to reach
the register file, from two points in the pipeline:

- **EX/MEM** — for a consumer immediately following its producer (0
  instructions apart)
- **MEM/WB** — for a consumer one instruction after its producer

EX/MEM takes priority when both could apply (e.g. the same destination
register written twice in a row). Store instructions get a separate
forwarding path (`fw_r2`) for the value being stored, since it's read
through `rs2` independent of whatever the ALU's second operand is doing —
without it, a store's data operand would never be forwarded when the store
uses an immediate for its address calculation.

Forwarding at the EX/MEM stage has to forward whatever the instruction will
*actually* write back, not just its raw ALU result — most instructions'
writeback value is their ALU result, but `LUI`/`JAL`/`JALR` write back
something else (the immediate, or the return address), and the ALU is still
computing its own equally-real-looking-but-architecturally-meaningless
result underneath. `datapath_pipelined.sv` reuses `writeback_mux` a second
time at the EX/MEM stage to compute the correct forwarded value before it
reaches `forward_unit.sv`.

**Load-use hazards (stalling).** A value loaded by `LW` isn't available
until the MEM stage, one stage later than an ALU result — so a consumer
immediately following a load can't be resolved by forwarding alone.
`hazard/hazard_detect.sv` detects this (a load in ID/EX whose destination
matches either source register of the instruction in IF/ID) and asserts
`stall`, which freezes the PC and IF/ID register for one cycle while a
bubble is inserted into ID/EX.

**Control hazards (flushing).** A taken branch or jump is only resolved in
EX, one stage after the next instruction has already been fetched. On a
taken branch/JAL/JALR, `datapath_pipelined.sv` flushes IF/ID (`flush`) so
the wrongly-fetched instruction never executes. `flush` and the load-use
`stall` bubble are separate signals — IF/ID needs to *hold* during a stall
(it already has its own `stall` input for that) but *flush* during a taken
branch, so a single combined signal driving both stall and flush would
zero out the instruction IF/ID is supposed to be holding.

## Testing

`tests/` holds testbenches for the pipelined core, each loading its own
program image and reporting pass/fail per check plus a final summary:

- **`skeleton_tb.sv`** — smoke test for the datapath skeleton before
  forwarding/hazard handling existed: ADDI/ADD/SW/LW and a taken BEQ, with
  instructions spaced far enough apart to avoid needing forwarding at all.
- **`forward_tests.sv`** — targeted forwarding coverage: EX/MEM and MEM/WB
  forwarding into both ALU operands, store-data forwarding (`fw_r2`) at
  both distances, forwarding priority, and forwarding into both operands of
  a branch comparison.
- **`complete_tests.sv`** — a full-pipeline stress test built around
  `program_full.asm`'s instruction-coverage sequence (every supported
  instruction, checkpointed to memory since it's a copy of a program
  written for the single-cycle core, and register reuse everywhere else,
  since instruction memory is capped at 64 words) plus explicit load-use
  stalling, store-data forwarding, forwarding priority, branch-operand
  forwarding, and a flush immediately followed by a load-use stall.
- **`hazard_matrix_tests.sv`** — the exhaustive version, split into 5
  independent phases (each under the 64-word instruction limit,
  sequentially loaded and run against a freshly reset DUT) covering: every
  forwarding distance for rs1, rs2, and both simultaneously; a fully
  chained dependency (every instruction depending on the one immediately
  before it, back to back); forwarding priority; back-to-back independent
  load-use stalls; `fw_r2` at both distances; branch operands forwarded
  from both EX/MEM and MEM/WB feeding a same-cycle taken decision; a
  taken branch immediately overlapping a load-use stall (including the
  stalled instruction being the branch itself); the `rd != 0` forwarding
  guard; JAL/JALR forwarding into an immediately-dependent instruction; and
  a regression test for the EX/MEM-forwarding-must-respect-writeback-value
  bug described above (a poisoned register bleeding into a 0-gap-forwarded
  `LUI` result).

## Assembler

`utils/assembler.py` is a small two-pass RV32I assembler covering every
instruction the datapath supports (see above). It reads `program.txt` from
the current directory and writes the assembled machine code to `program.hex`,
one 8-digit hex word per line, ready to be loaded by `instruction.sv`. It's
also what generated every `.hex` program used by the tests in `tests/` —
those are gitignored build artifacts; the testbenches embed their assembly
source in a header comment instead.

Syntax mirrors standard RISC-V assembly, e.g.:

```
    addi x1, x0, 5
    add  x3, x1, x2
    sw   x1, 0(x0)
    lw   x22, 0(x0)
beq_target:
    beq  x1, x2, beq_target
    jal  x25, some_label
    jalr x26, some_label(x0)
    lui  x23, 0x12345
```

Labels are any token ending in `:`, resolved in a first pass before machine
code is generated; `beq`/`jal` immediates are computed as PC-relative
offsets from the label address, while `jalr`'s immediate is `rs1 + imm`
as usual (only PC-relative automatically when the label is combined with a
`0` base, since `jalr`'s own immediate is never PC-relative by definition).

Run it from the directory containing `program.txt`:

```sh
python3 utils/assembler.py
```

`program_full.asm`/`program_full.txt` (plain instructions, no comments) are
provided as a reference program exercising every supported instruction —
useful for testing the assembler's output against the known-good
`program_full.hex` used by `datapath_full_tb.sv`.

## Memory

Both instruction and data memory are 64 words (256 bytes) deep, word-addressed
via `addr[7:2]`. Addresses at or beyond `0x100` wrap around instead of
erroring, so keep program code and data within that range. This applies to
both cores, and it's the reason the pipelined tests either checkpoint results
to memory and reuse registers, or split into multiple independently-loaded
phases, rather than writing one long program.

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

### Pipelined core

The pipelined core needs the pipeline registers and hazard/forwarding units
in addition to the modules above:

```sh
iverilog -g2012 -o sim_pipelined \
  alu/alu_pkg.sv control_unit/control_pkg.sv \
  alu/alu.sv register/register.sv instruction_mem/instruction.sv data_mem/data.sv \
  control_unit/control.sv \
  glue/pc.sv glue/pc_plus4.sv glue/branch_adder.sv glue/imm_gen.sv \
  glue/alu_src_mux.sv glue/pc_reg_mux.sv glue/jalr_adder_mux.sv \
  glue/writeback_mux.sv glue/pc_next_mux.sv \
  hazard/forward_unit.sv hazard/hazard_detect.sv \
  pipeline_regs/if_id_reg.sv pipeline_regs/id_ex_reg.sv pipeline_regs/ex_mem_reg.sv pipeline_regs/mem_wb_reg.sv \
  datapath_pipelined.sv tests/hazard_matrix_tests.sv

vvp sim_pipelined
```

Swap `tests/hazard_matrix_tests.sv` for any other testbench in `tests/` to
run it instead.
