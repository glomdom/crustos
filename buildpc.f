: spit ( a u -- ) >r begin c@+ stderr next ;
f<< /asm/i386.f
f<< /xcomp/pc/mbr.f
ORG $200 spit
f<< /xcomp/pc/i386.f
ORG here ORG - spit bye
