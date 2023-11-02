\ CRC implementations

?f<< cc/cc.f
cc<< lib/crc.c

\ Computes CRC32 over range `a u`
: crc32[] ( a u -- crc ) A>r >r >A -1 begin Ac@+ crc32 next -1 xor r>A ;
