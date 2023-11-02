\ i386 assembler
\ This assembler implies that the code will run in protected mode with the D
\ attribute set.

\ MOD/RM constants
0 const AX    1 const CX    2 const DX    3 const BX
4 const SP    5 const BP    6 const SI    7 const DI
0 const AL    1 const CL    2 const DL    3 const BL
4 const AH    5 const CH    6 const DH    7 const BH
5 const MEM \ mod 0 + r/m 5 == abs memory

\ Size modes
0 const SZ32
1 const SZ16
2 const SZ8

SZ32 value opsz
1 value opdirec \ 1: reg=tgt r/m=src | 0: reg=src r/m=tgt
3 value opmod \ by default, we're in "direct reg" mode
-1 value opreg \ -1 = unset
-1 value oprm \ -1 = unset
0 value imm? \ are we in immediate mode?
0 value imm \ value of current immediate, if set
0 value disp \ displacement value

\ Utilities
: asm$ SZ32 to opsz 1 to opdirec 3 to opmod -1 to opreg -1 to oprm 0 to imm? ;
: _err abort" argument error" ;
: _assert not if _err then ;
: w, here w! 2 allot ;

\ Force a value into `opreg`. If `opreg` is -1, we simply set it, but if it's set,
\ then we move `opreg` to `oprm` first.
: opreg! ( reg -- )
  opreg 0>= if
    oprm 0< _assert
    opreg to oprm then
  to opreg ;

: .asm ." sz " opsz . ."  d" opdirec . ."  mod " opmod . ."  reg " opreg .
  ."  r/m " oprm . ."  disp " disp .x
  ."  imm " imm? if imm .x else ." none" then nl> ;

\ Writing the operation

\ Write `opcode`, mixing it with `opdirec` and `opsz`
: op, ( opcode -- )
  opdirec << or opsz SZ8 = not or dup $ff > if w, else c, then ;

\ Write down `modrm`, errors out if not all parts are there.
: modrm, ( -- )
  opmod 3 lshift opreg or 3 lshift oprm or dup $100 < _assert c, ;

\ Write down `disp` if needed.
: disp, ( -- )
  opmod case
    0 of = oprm MEM = if disp , then endof
    1 of = disp c, endof
    2 of = disp , endof
  endcase ;

\ Write down an immediate.
: imm, ( -- )
  imm opsz case
    SZ32 of = , endof
    SZ16 of = w, endof
    SZ8 of = c, endof
    _err
  endcase ;

\ Write down `opcode` in modrm mode.
: opmodrm, ( opcode -- )
  op, modrm, disp, asm$ ;

\ Write down `opcode` in immediate mode.
: opimm, ( opcode opreg -- )
  0 to opdirec \ TODO: allow sign-extend by making this logic variable
  opreg! op, modrm, disp, imm, asm$ ;

\ Setting arguments

\ Words below are "frontend" words giving a convenient interface for setting
\ the assembler controlling variables. The idea is that executing a "lowercase
\ register" word selects that register. The first time, it's for the target,
\ the second time, it's for the source. For example, "ax bx mov," copies the
\ value of EBX into EAX.
\ Immediate values are set with "i)". For example, "ax 42 i) mov," copies 42
\ in EAX.
\ Indirect addressing mode is achieved by specifying a displacement with "d)".
\ For example, "ax bx 0 d) mov," copies the dword that EBX points at into EAX.
\ "ax bx 4 d) mov," does the same, but with EBX+4.
\ Absolute memory access is achieved with "m)". For example, "ax $1234 m) mov,"
\ copied the dword value at address $1234 into EAX.
\ 8bit operations are achieved with "l/h" register words. For example, "al ch
\ mov," copies the value of CH into AL.

: r! ( reg -- )
  opreg 0< if \ either the first argument or the other one is a mod/rm
    to opreg
  else \ second argument
    oprm 0< _assert \ more than 2 arguments
    to oprm
  then ;

: _ doer ( reg -- ) c, does> c@ r! ;
AX _ ax BX _ bx CX _ cx DX _ dx
SP _ sp BP _ bp SI _ si DI _ di

: _ doer ( reg -- ) c, does> c@ r! SZ8 to opsz ;
AL _ al
BL _ bl
CL _ cl
DL _ dl
AH _ ah
BH _ bh
CH _ ch
DH _ dh

: i) ( imm -- ) 1 to imm? to imm ;

: d) ( disp -- ) to disp
  oprm 0< if
    opreg to oprm
    -1 to opreg
    0 to opdirec
  then

  disp case
    of not oprm MEM = to opmod endof
    $100 of > 1 to opmod endof
    2 to opmod
  endcase ;

: m) ( addr -- ) to disp
  oprm 0< _assert
  opreg 0< if
    0 to opdirec then
  0 to opmod MEM to oprm ;

\ Operations

\ Inherent
: op ( opcode -- ) doer c, does> ( a -- ) c@ c, asm$ ;
$c3 op ret,

\ Conditional jumps
: op ( opcode -- ) doer , does> ( rel32 a -- ) @ op, , ;
$840f op jz,
$850f op jnz,

\ JMP and CALL
\ These are special. They can either be called with a modrm tgt, or with *no
\ argument at all*. In the latter case, an absolute addr to call is waiting on
\ PS. in the opcode structure, lower byte is the "direct" opcode and 2nd one is
\ the "opreg" for the modrm version.
: op ( opcode -- ) doer , does> @ ( rel32? opcode -- )
  opreg 0< if
    c, here - 4 - , asm$
  else
    8 rshift opreg! $ff opmodrm,
  then ;
$04e9 op jmp,
$02e8 op call,

\ Single operand
\ opcode format 00000000 00000rrr mmmmmmmm mmmmmm00
\ r = opreg override
\ m = modrm opcode
: op ( reg opcode -- ) doer , does> @ ( opcode -- )
  dup 16 rshift opreg! $ffff and opmodrm, ;
$0400f7 op mul,    $0300f7 op neg,    $0200f7 op not,
$0100ff op dec,    $0000ff op inc,
$009f0f op setg,   $009c0f op setl,   $00940f op setz,    $00950f op setnz,

\ Two operands
\ opcode format 00000000 ssssssss iiiiirrr mmmmmm00
\ s = "shortcut" opcode, when target is AX
\ i = immediate opcode, with b7 (always 1) is left off
\ r = immediate opreg override
\ m = modrm opcode
: op ( opcode -- ) doer , does> @ ( opcode )
  imm? if
    8 rshift dup >> $fc and $80 or swap 7 and opimm,
  else $ff and opmodrm, then ;
$040000 op add,    $3c0738 op cmp,     $2c0528 op sub,     $a8f084 op _test,
$240420 op and,    $0c0108 op or,      $340630 op xor,

\ Shifts. They come in 2 versions. The "naked" version is imm-only. The "cl"
\ versions has CL as an inherent argument.
: op ( opcode -- ) doer , does> @ dup 8 rshift
  imm? _assert opreg! c, modrm, disp, imm c, asm$ ;
$04c1 op shl,
$05c1 op shr,

: op ( opcode -- ) doer , does> @ dup 8 rshift
  imm? not _assert opreg! c, modrm, disp, asm$ ;
$04d3 op shlcl,
$05d3 op shrcl,

\ Push/Pop
: op ( op -- ) doer c, does> c@ ( opcode -- )
  oprm 0< _assert opsz SZ8 = not _assert opreg or c, asm$ ;
$58 op pop,
$50 op push,

\ MOV has a special reg<-imm shortcut
: mov,
  imm? if opmod 3 = if \ mov reg, imm shortcut
      $b0 opsz SZ8 = not 3 lshift or opreg or c, imm, asm$
    else $c7 c, 0 opreg! modrm, disp, imm, asm$ then
  else $88 opmodrm, then ;

\ TEST can only have one direction
: test, 0 to opdirec _test, ;
