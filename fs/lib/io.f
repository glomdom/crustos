\ I/O Aliases

\ Defines stdin (and soon stdout) which is used by many programs and words as
\ their main I/O. In addition to those words, this subsystem also implements
\ some convenience words to manage where they point to.

alias in< stdin ( -- c )
