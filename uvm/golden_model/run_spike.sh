#!/bin/bash
cd /mnt/c/Users/shady/riscv-vivado/riscv-vivado.sim/sim_1/behav/xsim
/home/shady_wsl/fpga_ws/risc-v/spike/build/spike --isa=rv32i -m0x0:0x1000,0x80010000:0x10000 --pc=0x100 --log-commits --instructions="$1" "$2" > /dev/null 2> "$3"
