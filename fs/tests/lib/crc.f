\ Tests for crc.f

?f<< tests/harness.f
?f<< lib/crc.f

testbegin

S" crustosbest" c@+ crc32[] $1b587e62 #eq

testend
