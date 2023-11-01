?f<< lib/dict.f
?f<< lib/nfmt.f

: raddr>entry ( a -- w ) current begin 2dup < while prevword repeat nip ;
: .raddr ( a -- ) dup .x raddr>entry ?dup if spc> .word then ;
: .btrace nl> begin rcnt while r> .raddr nl> repeat unaliases abort ;
' .btrace to abort
