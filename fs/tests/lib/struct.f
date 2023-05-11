\ Struct Testing

?f<< tests/harness.f
?f<< lib/struct.f

testbegin

struct Pos field pos.x field pos.y
here to Pos 42 , 12 ,
pos.x 42 #eq
pos.y 12 #eq
4 to+ pos.x
pos.x 46 #eq
Pos here to Pos 102 , 34 ,
pos.y 34 #eq
to Pos
pos.y 12 #eq

testend
