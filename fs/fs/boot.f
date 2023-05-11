\ Boot Filesystem Implementation

\ This is a subset of FAT16. It is designed to be embedded
\ right after `boot.f` and provide the means to continue bootstrapping
\ on.

\ Its goal is to provide fopen and fread. Nothing more. The rest of the
\ FAT16 implementation is in drv/fat16.f

\ This unit has access to a very small set of words, that is, words implemented
\ by boot.f as well as the `drive` protocol, which is implemented by a driver
\ that is inserted between boot.f and this unit.
