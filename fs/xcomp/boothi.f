0 value curhdl   \ handle of the file currently being read
0 value fecho

: f< ( -- c )
  1 curhdl dup @ execute if c@ else -1 then
  fecho if dup emit then ;
: fload ( id -- )
  dup floaded, curhdl >r
  fopen to curhdl
  to' in< @ >r ['] f< to in<
  begin maybeword ?dup if runword 0 else 1 then until
  r> to in< curhdl dup 16 + @ ( 'fclose ) execute r> to curhdl ;

0 S" init.f" fchild fload
