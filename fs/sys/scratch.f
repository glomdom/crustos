\ System Scratchpad
?f<< /lib/scratch.f

\ There is only one system scratchpad, but you can create specialized pads for
\ specific purposes. One such purpose is sys/files cursors, where that data to
\ scratch is small, but can be long lived (a long running forth script). If
\ these cursor live in the system scratchpad, they'd be overwritten by faster-
\ paced data.

\ WHAT THE FUCK? CC has memory corruption when working with a 0x4000 scratchpad..
$8000 scratchpad$ syspad
syspad to Scratchpad
