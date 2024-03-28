: spit ( a u -- ) >r begin c@+ stderr next ;
f<< /asm/i386.f
f<< /xcomp/pc/mbr.f
f<< /xcomp/pc/boot.f

ORG $400 spit bye
