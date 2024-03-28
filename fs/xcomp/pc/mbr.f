\ x86 bootloader

$7c00 const BINSTART
BINSTART $1e0 + const GDTADDR

0 value L1
1 to realmode

create ORG here $400 0 fill
forward jmp, to L1 \ bypass BPB
$23 allot L1 forward!
cli, cld, GDTADDR m) lgdt,
ax $0003 i) mov, $10 int, \ video mode 80x25

\ read sector 2 from boot floppy in memory at address $8000
ax $0201 i) mov, bx $8000 i) mov, cx $0002 i) mov, dx $0000 i) mov, $13 int,
ax cr0 mov, ax 1 i) or, cr0 ax mov,

$08 0 jmpfar, here ORG - BINSTART + here 4 - w! 0 to realmode

\ initialize segments
ax 16 i) mov,
ds ax mov,
ss ax mov,
es ax mov,
gs ax mov,
fs ax mov,

\ jump to payload
$08 $8000 jmpfar,

\ taken from GNU Grub @ grub-core/kern/i386/realmode.S
ORG $1e0 + to here \ GDT

\ first entry (the null entry) is a reference to itself
$17 w, GDTADDR , 0 w,

\ code segment. base=0, limit=ffffff*4kb, present, exec/read, DPL=0
$ffff w, 0 w, 0 c, $9a c, $cf c, 0 c,

\ data segment. base=0, limit=ffffff*4kb, present, read/write, DPL=0
$ffff w, 0 w, 0 c, $92 c, $cf c, 0 c,

ORG $1fe + to here $55 c, $aa c,
