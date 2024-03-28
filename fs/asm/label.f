\ Cross-arch labels and flow

0 value org
0 value binstart

: pc here org - binstart + ;
: pc>addr ( pc -- a ) org + binstart - ;

: abs>rel ( a -- rel32 ) pc - ;

: forward here 0 ;