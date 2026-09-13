ENTRY(_start)
SECTIONS
{
  . = 0x0;
  .text : { *(.text) }
  /DISCARD/ : { *(.riscv.attributes) }
}
