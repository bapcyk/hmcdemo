HPFilter hpf
hpf configure -datatype flt -datatypes {phys}
Saver saver1
saver1 listen -on
saver listen -on
listen phvals:hpf
listen hpf:saver1
serial open 4
sensor poll -loop
