\ i386 assembler
?f<< /asm/label.f

\ MOD/RM constants
0 const AX    1 const CX    2 const DX    3 const BX
4 const SP    5 const BP    6 const SI    7 const DI
0 const AL    1 const CL    2 const DL    3 const BL
4 const AH    5 const CH    6 const DH    7 const BH
0 const ES    1 const CS    2 const SS    3 const DS
4 const FS    5 const GS
4 const SIB \ mod 0/1/2 + r/m 4 == SIB

0 value op8b    \ is current op 8bit?
0 value opsreg  \ if we have a "special" reg, this contains the override opcode
1 value opdirec \ 1: reg=tgt r/m=src | 0: reg=src r/m=tgt
3 value opmod   \ by default, we're in "direct reg" mode
-1 value opreg  \ -1 = unset
-1 value oprm   \ -1 = unset
0 value imm?    \ are we in immediate mode?
0 value imm     \ value of current immediate, if set
0 value disp    \ displacement value
0 value sib     \ value of the SIB byte
0 value realmode

\ Utilities
: asm$ 0 to op8b 0 to opsreg 1 to opdirec 3 to opmod -1 to opreg -1 to oprm
  0 to imm? ;
: _err asm$ abort" argument error" ;
: _assert not if _err then ;
: w, here w! 2 allot ;
: isbyte? ( n -- f ) $100 < ;
: is16bit? realmode ;

\ in 16bit, abs mem = mod0 + rm 6, in 32-bit its rm 5
: memoprm 5 is16bit? + ;
: maybe8b ( opcode -- opcode ) op8b not or ;
: dw, is16bit? if w, else , then ;
: dwc, op8b if c, else dw, then ;

\ Force a value into `opreg`. If `opreg` is -1, we simply set it, but if it's set,
\ then we move `opreg` to `oprm` first.
: opreg! ( reg -- )
  opreg 0>= if
    oprm 0< _assert
    opreg to oprm
    0 to opdirec then
  to opreg ;

: .asm ." 8b? " op8b . ."  d" opdirec . ."  mod " opmod . ."  reg " opreg .
  ."  r/m " oprm . ."  disp " disp .x
  ."  imm " imm? if imm .x else ." none" then nl> ;

\ Writing the operation

\ Write `opcode`, mixing it with `opdirec` and `op8b`
: op, ( opcode -- )
  opdirec << or dup 8 rshift $ff and ?dup if c, then c, ;

\ Write down `modrm`, errors out if not all parts are there.
: modrm, ( -- )
  opmod 3 lshift opreg or 3 lshift oprm or dup $100 < _assert c, ;

\ Write down the SIB byte.
: sib, ( -- )
  oprm SIB = opmod 3 < and if sib c, then ;

\ Write down `disp` if needed.
: disp, ( -- )
  opmod case
    0 of = oprm memoprm = if disp dw, then endof
    1 of = disp c, endof
    2 of = disp dw, endof
  endcase ;

: msd, modrm, sib, disp, ;

\ Write down an immediate.
: imm, ( -- )
  imm dwc, ;

\ Write down `opcode` in modrm mode.
: opmodrm, ( opcode -- )
  op, msd, asm$ ;

\ Write down `opcode` in immediate mode.
: opimm, ( opcode opreg -- )
  0 to opdirec \ TODO: allow sign-extend by making this logic variable
  opreg! maybe8b op, msd, imm, asm$ ;

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

: _ doer ( reg -- ) c, does> c@ ( reg ) r! 1 to op8b ;
AL _ al   BL _ bl   CL _ cl   DL _ dl   AH _ ah   BH _ bh   CH _ ch   DH _ dh

: _ doer ( reg -- ) c, does> c@ ( reg ) opreg! $8c to opsreg ;
ES _ es   SS _ ss   DS _ ds   FS _ fs   GS _ gs

: _ doer ( reg -- ) c, does> c@ ( reg ) opreg! $0f20 to opsreg ;
0 _ cr0   2 _ cr2   3 _ cr3

: _ doer ( reg -- ) c, does> c@ ( reg ) opreg! $0f21 to opsreg ;
0 _ dr0   1 _ dr1   2 _ dr2   3 _ dr3   6 _ dr6   7 _ dr7

: _ doer ( reg -- ) c, does> c@ ( reg ) opreg! $0f24 to opsreg ;
6 _ tr6   7 _ tr7

: i) ( imm -- ) 1 to imm? to imm ;

: is16breg>[oprm] ( reg ) case
    SI of = 4 endof
    DI of = 5 endof
    BP of = 6 endof
    BX of = 7 endof
    _err
  endcase ;

: d) ( disp -- ) to disp
  oprm 0< if
    opreg to oprm
    -1 to opreg
    0 to opdirec
  then

  is16bit? if oprm is16breg>[oprm] to oprm then
  oprm SP = if $24 to sib then \ special case for ESP

  disp case
    of not oprm memoprm = to opmod endof
    of isbyte? 1 to opmod endof
    2 to opmod
  endcase ;

: m) ( addr -- ) to disp
  oprm 0< _assert
  opreg 0< if
    0 to opdirec then
  0 to opmod memoprm to oprm ;

\ Operations

\ Inherent
: op ( opcode -- ) doer c, does> ( a -- ) c@ c, asm$ ;
$c3 op ret,        $90 op nop,         $fa op cli,         $fa op cld,

\ Jumps and relative addresses
: rel, ( rel32-or-16 ) is16bit? if 3 - w, else 5 - , then ;

\ Conditional jumps
: op ( opcode -- ) doer , does> ( rel32-or-16 a -- ) @ op, rel, ;
$0f84 op jz,        $0f85 op jnz,

\ JMP and CALL
\ These are special. They can either be called with a modrm tgt, or with *no
\ argument at all*. In the latter case, an absolute addr to call is waiting on
\ PS. in the opcode structure, lower byte is the "direct" opcode and 2nd one is
\ the "opreg" for the modrm version.
: op ( opcode -- ) doer , does> @ ( rel32-or-16? opcode -- )
  opreg 0< if
    c, rel, asm$
  else
    8 rshift opreg! $ff opmodrm,
  then ;
$04e9 op jmp,      $02e8 op call,

: jmpfar, ( seg16 absaddr ) $ea c, dw, w, ;
: callfar, ( seg16 absaddr ) $9a c, dw, w, ;

: forward! ( jmpaddr - )
  c@+ $0f = if 1+ then pc over - ( a rel )
  is16bit? if 2 - swap w! else 4 - swap ! then ;

\ Single operand
\ opcode format 00000000 00000rrr mmmmmmmm mmmmmmmm
\ r = opreg override
\ m = modrm opcode
: op ( reg opcode -- ) doer , does> @ ( opcode -- )
  dup 16 rshift opreg! $ffff and opmodrm, ;
$0400f7 op mul,    $0300f7 op neg,     $0200f7 op not,
$0100ff op dec,    $0000ff op inc,
$000f9f op setg,   $000f9c op setl,    $000f94 op setz,    $000f95 op setnz,
$020f01 op lgdt,   $030f01 op lidt,

\ Two operands
\ opcode format 00000000 ssssssss iiiiirrr mmmmmm00
\ s = "shortcut" opcode, when target is AX
\ i = immediate opcode, with b7 (always 1) is left off
\ r = immediate opreg override
\ m = modrm opcode
: op ( opcode -- ) doer , does> @ ( opcode )
  imm? if
    8 rshift dup >> $fc and $80 or swap 7 and opimm,
  else $ff and maybe8b opmodrm, then ;
$040000 op add,    $3c0738 op cmp,     $2c0528 op sub,     $a8f084 op _test,
$240420 op and,    $0c0108 op or,      $340630 op xor,

\ TEST can only have one direction.
: test, 0 to opdirec _test, ;

\ Shifts. They come in 2 versions. The "naked" version is imm-only. The "cl"
\ versions has CL as an inherent argument.
: op ( opcode -- ) doer , does> @ dup 8 rshift
  imm? _assert opreg! c, msd, imm c, asm$ ;
$04c1 op shl,
$05c1 op shr,

: op ( opcode -- ) doer , does> @ dup 8 rshift
  imm? not _assert opreg! c, msd, asm$ ;
$04d3 op shlcl,
$05d3 op shrcl,

\ Push/Pop
: op ( op -- ) doer c, does> c@ ( opcode -- )
  oprm 0< _assert op8b not _assert opreg or c, asm$ ;
$58 op pop,
$50 op _push,

\ PUSH can also push an immediate.
: push, imm? if
  op8b if $6a else $68 then c, imm, asm$ else
  _push, then ;

\ MOV has a special reg<-imm shortcut
: mov,
  imm? if opmod 3 = if \ mov reg, imm shortcut
      $b0 op8b not 3 lshift or opreg or c, imm, asm$
    else $c7 c, 0 opreg! msd, imm, asm$ then
  else
    opsreg if opsreg else $88 maybe8b then opmodrm, then ;

\ INT is special
: int, ( n -- ) $cd c, c, ;
