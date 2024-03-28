\ Called when bootloader has finished loading the kernel as
\ well as the forth boot code following it in memory.
\ Still in realmode, SS uninitialized. Code is at $8000
ax $0e50 i) mov,
$10 int,
0 jmp,
