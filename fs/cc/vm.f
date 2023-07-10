\ C Compiler Virtual Machine
\ Requires asm

\ The goal of this VM is to provide a unified API for code generation of a C
\ AST across CPU architecture.

\ Computation done by this generated code is centered around the "Result".
\ concept. The goal is to make the CPU move bits around towards that Result.
\ The Result always lives on a particular register reserved for this role. For
\ example, on x86, it's EAX.

\ The VM very often interacts with the Result through another concept: the
\ Operand. Moving from the operand to the result, from the result to the
\ operand, running an operation on both the Result and the operand, etc.

\ The Operand doesn't live in a particular register, it comes from multiple
\ types of sources. Its possible values are:

\ None: no operand specified
\ Constant: a constant value
\ Stack Frame: an address on the Stack Frame
\ Register: value currently being held in an "alternate" register (EBX on x86)

\ We operate the VM by first specifying an operand, moving the operand toward
\ the result, performing ops, moving the result out. If we need to keep an
\ intermediate result for later, we can push it to a stack (the mechanism for
\ this is arch-specific). The pushed result can be later pulled backed into the
\ Operand.

\ To avoid errors, moving an operand to a non-empty and non-pushed Result is an
\ error. To set the operand when it's not none it's also an error.

\ For usage example, see tests/cc/vm.f

: _err abort" vm err" ;
: _assert not if _err then ;

\ Exec Context
0 value argsz
0 value locsz
0 value callsz

\ Register Management
6 const REGCNT
create registers AX c, BX c, CX c, DX c, SI c, DI c,
0 value reglvl

: curreg ( -- regid )
  reglvl REGCNT < if
    registers reglvl + c@ ( regid ) else
    eax push, AX ( regid ) then ;
: regallot ( -- regid ) curreg 1 to+ reglvl ;
: regfree ( -- )
  reglvl not if abort" too many regs free" then
  -1 to+ reglvl reglvl REGCNT >= if eax pop, then ;

\ Operand Definitions and Selection
$00 const VM_NONE
$01 const VM_CONSTANT       \ 42
$02 const VM_STACKFRAME     \ ebp+x
$03 const VM_REGISTER       \ eax
$04 const VM_CONSTANTARRAY  \ pointer to an array with the 1st elem being length
$11 const VM_*CONSTANT      \ [1234]
$12 const VM_*STACKFRAME    \ [ebp+x]
$13 const VM_*REGISTER      \ [eax]

\ 2 operands, 2 fields each (type, arg) - 4b per field
create operands 16 allot0
operands value 'curop
: selop1 ( -- ) operands to 'curop ;
: selop2 ( -- ) operands 8 + to 'curop ;
: selectedop ( -- n ) 'curop operands = not ;
: optype ( -- type ) 'curop @ ;
: optype! ( type -- ) 'curop ! ;
: oparg ( -- arg ) 'curop 4 + @ ;
: oparg! ( arg -- ) 'curop 4 + ! ;

\ reinitialize both ops to VM_NONE and dealloc registers if needed
: opdeinit optype $f and VM_REGISTER = if regfree then VM_NONE optype! ;

\ deinit both ops and select op1
: ops$
  selop2 opdeinit selop1 opdeinit
  reglvl if abort" unbalanced reg allot/free" then
  operands 16 0 fill ;
: .ops 4 >r operands begin dup @ .x spc> 4 + next drop nl> ;

\ Managing Operands
: hasop# optype VM_NONE = not _assert ;
: noop# optype VM_NONE = _assert ;
: const>op ( n -- ) noop# VM_CONSTANT optype! oparg! ;
: constarray>op ( a -- ) noop# VM_CONSTANTARRAY optype! oparg! ;
: sf+>op ( off -- ) noop# VM_*STACKFRAME optype! oparg! ;
: mem>op ( off -- ) noop# VM_*CONSTANT optype! oparg! ;

\ Get current operand SF offset, adjusted with callsz
: opsf+ ( -- off ) oparg callsz + ;

\ Resolve current operand as an assembler "src" argument
: opAsm ( -- )
  optype case
    VM_CONSTANT of = oparg i32 endof
    VM_STACKFRAME of = abort" can't address VM_STACKFRAME directly " endof
    VM_REGISTER of = oparg r! endof
    VM_*CONSTANT of = oparg [i32] endof
    VM_*STACKFRAME of = opsf+ [ebp]+ endof
    VM_*REGISTER of = oparg [r]! endof
  _err endcase ;

\ Force current operand to be copied to a register
: op>reg optype
  case
    VM_NONE of = _err endof
    VM_REGISTER of = endof
    VM_*REGISTER of = endof
    VM_STACKFRAME of =
      regallot dup r! ebp mov,
      opsf+ if dup r! opsf+ i32 add, then
      oparg! VM_REGISTER optype! endof
    regallot dup r! opAsm mov, oparg! VM_REGISTER optype!
  endcase ;

\ Resolve any referencing into a "simple" result. A VM_STACKFRAME goes into a
\ register, a VM_*REGISTER is resolved into a VM_REGISTER
: opderef
  optype case
    VM_STACKFRAME of = op>reg endof
    VM_*CONSTANT of = op>reg endof
    VM_*STACKFRAME of = op>reg endof
    VM_*REGISTER of = oparg r! oparg [r]! mov, VM_REGISTER optype! endof
  endcase ;

\ Before doing an operation on two operands, we verify that they are compatible
\ e.g. we can't have two VM_*REGISTER ops - one of them has to be dereferenced (it HAS to be op2)
: maybederef
  selop1 optype VM_*REGISTER = optype $f and VM_STACKFRAME = or if
    selop2 opderef then ;

\ If possible, transform current operand in its reference
: &op>op
  optype case
    VM_*STACKFRAME of = VM_STACKFRAME optype! endof
    VM_*CONSTANT of = VM_CONSTANT optype! endof
    VM_*REGISTER of = VM_REGISTER optype! endof
  _err endcase ;

\ If possible, dereference current operand
: *op>op
  optype case
    VM_CONSTANT of = VM_*CONSTANT optype! endof
    VM_*CONSTANT of = op>reg *op>op endof
    VM_STACKFRAME of = VM_*STACKFRAME optype! endof
    VM_*STACKFRAME of = op>reg *op>op endof
    VM_REGISTER of = VM_*REGISTER optype! endof
    VM_*REGISTER of = opderef VM_*REGISTER optype! endof
  _err endcase ;

\ Force the op into a register and then reset the op to VM_NONE
: oppush ( -- oparg optype ) oparg optype VM_NONE optype! ;

\ Assuming the current op is VM_NONE, set it back to VM_REGISTER, and
\ set its arg to the current register at reglvl
: oppop ( oparg optype -- ) noop# optype! oparg! ;

\ Swap op1 and op2 types/args
: op1<>op2
  selop1 optype oparg
  selop2 oparg swap oparg! optype rot optype!
  selop1 optype! oparg! ;

\ Code generation - Functions, Calls, Returns

\ Generate function prelude code by allocating 'locsz' bytes on PS
: vmprelude, ( argsz locsz -- )
  to locsz to argsz
  locsz if ebp locsz i32 sub, then ;

\ Deallocate locsz and argsz. If result is set, keep a 4b in here and push the result there
: vmret,
  selop2 noop#
  locsz argsz + selop1 optype if 4 - then
  opderef
  ?dup if ebp i32 add, then
  optype if [ebp] opAsm mov, then
  ret, ;

: callargallot, ( bytes -- ) dup to callsz ebp i32 sub, ;

: vmcall>op1, ( -- )
  VM_CONSTANT optype = _assert
  oparg execute, VM_NONE optype!
  selop1 noop#
  VM_REGISTER optype! regallot dup oparg! r! [ebp] mov,
  ebp 4 i32 add, 0 to callsz ;

\ Code Generation - BinaryOps

: binopprep ( -- )
  selop1 op>reg opAsm
  selop2 hasop# opAsm ;
: vmadd, binopprep add, opdeinit ;
: vmsub, binopprep sub, opdeinit ;
: vmmul,
  reglvl 4 >= if edx push, then
  selop1 op>reg oparg AX = not if eax push, eax opAsm mov, then
  selop2 op>reg hasop# opAsm mul, opdeinit
  selop1 oparg AX = not if opAsm eax mov, eax pop, then
  reglvl 4 >= if edx pop, then ;
: vmmov,
  selop2 optype VM_CONSTANTARRAY = if
    selop1 optype VM_STACKFRAME = _assert
    *op>op selop2 oparg selop1 dup @ >r begin
      opAsm 4 + dup @ i32 mov, oparg 4 + oparg! next
    drop selop2
  else
    maybederef selop1 opAsm selop2 opAsm mov, then
  opdeinit ;

\ Code Generation - UnaryOps

: unaryopprep op>reg opAsm ;
: vmneg, unaryopprep neg, ;
: vmnot, ( ~ ) unaryopprep not, ;
: vmboolify, unaryopprep
  opAsm test,
  opAsm 0 i32 mov,
  opAsm setnz, ;
: vmboolnot, unaryopprep
  opAsm test,
  opAsm 0 i32 mov,
  opAsm setz, ;

\ pre-inc/dec op1
\ TODO: *opAsm goes below, not opAsm. Increment the reference, not the result
: vm++op, opAsm inc, ;
: vm--op, opAsm dec, ;

\ post-inc/dec op1
\ TODO: we dont use both ops for this and thus allow post-inc/dec and post-dec/inc to run on either on the 2 ops
: _ ( 'w -- )
  selop1 optype VM_*STACKFRAME = _assert
  selop2 noop# selop1 optype oparg selop2 oparg! optype!
  selop1 op>reg selop2 opAsm execute opdeinit selop1 ;
: vmop++, ['] inc, _ ;
: vmop--, ['] dec, _ ;

\ Code Generation - Logic

: _
  selop1 op>reg opAsm selop2 opAsm cmp, opdeinit
  selop1 opAsm 0 i32 mov, ;
: vm<, _ opAsm setl, ;
: vm==, _ opAsm setz, ;
: _ ( 'w -- ) selop1 opAsm selop2 opAsm execute opdeinit selop1 vmboolify, ;
: vm&&, ['] and, _ ;
: vm||, ['] or, _ ;
: vmjmp! ( 'jump_addr -- ) here over - 4 - swap ! ;
: vmjmp, 0 jmp, here 4 - ;
: vmjz, ( -- addr )
  selop1 opAsm opAsm test, opdeinit
  0 jz, here 4 - ;
: vmjnz, ( -- addr )
  selop1 opAsm opAsm test, opdeinit
  0 jnz, here 4 - ;
