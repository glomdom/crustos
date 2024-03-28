\ This will be the i386 crust kernel. It's called when the bootloader has finished
\ loading this binary as well as the forth boot code following it in memory.
\ In protected mode, all segments initialized. ESP and EBP uninitialized.

$8000 const BINSTART \ code lives at $8000
create ORG
ax $07690748 i) mov,
$b8000 m) ax mov,
0 jmp, \ el infinito loopo
