?f<< tests/harness.f
?f<< sys/file.f

testbegin

\ chdir and relative find
S" lib" chdir
S" str.f" findpath # \ found
S" /lib/str.f" findpath # \ found

\ lets go back one
S" .." chdir
S" lib/str.f" findpath # \ found
S" /lib/str.f" findpath # \ found

\ non-existant files?
S" lib/nope.f" findpath not #
S" /nope.f" findpath not #

testend
